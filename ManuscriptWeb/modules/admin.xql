module namespace admin = "http://exist-db.org/apps/ManuscriptWeb/admin";

import module namespace config="http://exist-db.org/apps/ManuscriptWeb/config" at "config.xqm";
import module namespace mw ="http://exist-db.org/apps/ManuscriptWeb/mw" at "mw.xql";
import module namespace viewstuff="http://exist-db.org/apps/ManuscriptWeb/fun" at "view-functions.xql";
import module namespace functx="http://www.functx.com"; 


(:updates the text-content of a node. returns the new text content or "empty", if the text was deleted completely (assuming that text must be set) :)
(:TODO: change this completely! resource ID and elementname should be sufficient to change element's text content:)
declare function admin:updateNodeText($resourceId as xs:string?, $nodeType as xs:string?, $newText as xs:string?) {
   
    let $node := collection($config:data-root)//id($resourceId)/*[name()=$nodeType][1]
    let $document := root($node)
    let $noEmpty := if ($newText) then ($newText) else ("empty")
    (:if a <label> element is changed, also adjust the <urllabel> for url-mapping! :)
    let $add := if ($node/name()="label") then (
            let $newLabel := admin:unifyLabel($document, $noEmpty, $resourceId)

            let $newURLlabel := admin:createURLIdentifier($newLabel)
            let $setURLlabel := update replace $node/parent::*/urllabel with <urllabel>{$newURLlabel}</urllabel>
            (: if you want to have the label and the url label identical, e.g. return $newURLlabel here instead... but then
            the label is always camelcased and URL encoded... meh... :)
            return $newLabel
    ) else ($noEmpty)
    let $update := update value $node with $add
    
    return map{'id': $resourceId, 'operation': 'updateText', 'success': "true", 'node' : $nodeType, 'value' : $add} 
};


declare function admin:createDocument($entrypoint as xs:string?){
    let $moduleType := mw:getModuleType($entrypoint)
    (:todo: potentially get this into a local function? :)
    let $docType := switch ($moduleType)
                        case "notes" return "notebook"
                        case "editions" return "edition"
                        case "library" return "book"
                        case "drafts" return "draft"
                        default return $moduleType
                        
    
                        
    let $newDocumentId := admin:createUniqueID($docType)
    let $path := mw:getCollectionPathById($entrypoint)
    
    let $configFile := doc(concat($path,'/config.xml'))
    let $config := $configFile/contents
    
    let $docLabel := admin:unifyLabel($configFile, concat("new ",$docType), $newDocumentId)
    
    let $documentXML := 
            <doc xml:id="{$newDocumentId}">
                <label>{$docLabel}</label>
                <urllabel>{admin:createURLIdentifier($docLabel)}</urllabel>
            </doc>
    let $insert := update insert $documentXML into $config
    
    (:create folders:)
    let $newDocumentFolder := xmldb:create-collection($path, $newDocumentId)
    let $newTranscriptFolder := xmldb:create-collection(concat($path,'/',$newDocumentId), 'transcripts')
    let $newFacsimileFolder := xmldb:create-collection(concat($path,'/',$newDocumentId), "facsimiles")
    let $mediumSizeFolder := if ($newFacsimileFolder) then xmldb:create-collection($newFacsimileFolder,"medium") else ""
    let $thumbsFolder := if ($newFacsimileFolder) then xmldb:create-collection($newFacsimileFolder,"thumbs") else ""
    (:TODO: mapping.xml file must be added!:)
    let $emptyMapping := <mapping>
                            <transcriptSequence/>
                            <imageSequence/>
                            <zoneMap/>
                          </mapping>

    let $newMappingFile := xmldb:store($newDocumentFolder,"mapping.xml",$emptyMapping)
    return $documentXML
};




(: create a new collection within the resource of the resource-id $entrypoint, 
    $entrypoint: module-id or a collection-id:)
declare function admin:createCollection($entrypoint as xs:string?){
    let $newCollectionId := admin:createUniqueID('collection')
    let $path := mw:getCollectionPathById($entrypoint)
  
    (:new collection entry in config.xml:)
    let $configFile := doc(concat($path,'/config.xml'))
    let $config := $configFile/contents
    let $collectionXML := util:deep-copy(doc($config:app-root || "/config/resource-config-default.xml")/resources/collection[1])
    (:add the new ID to the copy of the default xml configuration:)
    let $elementWithId := functx:add-attributes($collectionXML, xs:QName('xml:id'), $newCollectionId)
    let $insert := update insert $elementWithId into $config
    
    (:new eXist-collection in $path:)
    let $newCollection := xmldb:create-collection($path,$newCollectionId)
    (:copy default icon into collection folder and rename it :)
    let $copyDefaultIcon := xmldb:copy-resource($config:app-root || "/resources/icons/" , "default_collection.png" , $newCollection, "collection-icon.png")
    (:xmldb:copy($config:app-root || "/resources/icons/", $newCollection , 'default_collection.png'):)
    
    (:add new config file for this collection:)
    let $emptyConfig := doc($config:app-root ||  "/config/collections-config-default.xml")
    let $createConfig := xmldb:store($newCollection,"config.xml",$emptyConfig)
    
    
    let $label := admin:unifyLabel($configFile, $collectionXML/label/text(), $newCollectionId)
    let $updateLabel := update value $config/id($newCollectionId)/label[1] with $label

    
    (:update URL: generate a new URL-encoded and camelcased URL-label from the resources label:)
    let $newURL := admin:createURLIdentifier($label)
    let $updateURLlabel := update insert <urllabel>{$newURL}</urllabel> into $config/id($newCollectionId)
    (:return <div id='thatDeck' class="row">{viewstuff:show-collections($entrypoint)}</div> :)
    
    let $collection := $config/id($newCollectionId)
    
    (:in return: url might have to go back to mw:getAbsoluteURLpath($moduleID):)
    return map{
            'success'       :       'true',
            'operation'     :       'createCollection',
            'id'            :       $newCollectionId,
            'label'         :       $collection/label[1],
            'urllabel'      :       $collection/urllabel[1],
            'url'           :       mw:getRelativeURLpath($newCollectionId),
            'description'   :       $collection/description[1]
    }
};


(:todo: pass only the resourceID:)
declare function admin:deleteCollection($resourceId as xs:string?){
    
    let $node-to-delete := collection($config:data-root)//id($resourceId)
    
    let $collectionID := data($node-to-delete/@xml:id)
    (: $parentCollectionID must be set here, because the resource with $collectionID won't exist anymore after 'update delete':)
    let $parentCollectionID := mw:getParentCollectionId($collectionID) 
    
    (:delete the collection folder:)
    let $CollectionPath := mw:getCollectionPathById($collectionID)
    let $deleteCollection := if (contains($CollectionPath,$config:data-root)) then (xmldb:remove(xs:anyURI($CollectionPath))) else ""
    (:delete the collection from the regarding config.xml file:)
    let $bar := update delete $node-to-delete
    (:return cards for the remaining collections:)
    let $logThis := util:log('info', concat($deleteCollection," was deleted"))
    
    return map {
            'id'        :   $collectionID, 
            'operation' :   'deleteCollection', 
            'success'   :   "true"}
    
};



(:delete the module with the id $nodeId:)
(:TODO: pass only the resourceId!:)
declare function admin:deleteModule($resourceId as xs:string?){
    let $node-to-delete := collection($config:data-root)//id($resourceId)

    (:delete the complete folder in data:)
    let $colPath :=mw:getCollectionPathById($resourceId)
    let $deleteCollection := if (contains($colPath,$config:data-root)) then xmldb:remove(xs:anyURI($colPath)) else ""
    let $bar := update delete $node-to-delete
    let $log := util:log('info',concat("death to: ",$colPath))
    
     return map {'id': $resourceId, 'operation': 'delete', 'success': "true"}
};

(:moves a module 'left' or 'right' by swapping it with its following/preceding sibling:)
(:todo: pass the resource ID and the direction, instead of "FileID+nodeID", move the resource left or right, if possible. else return false:)
declare function admin:moveModule($resourceId as xs:string?, $direction as xs:string?) {    
    (: todo: security and flow-controll: make sure variables are set, make sure $document is existing etc - 
    currently it can happen that a module is deleted because its left or right neightbour does not exist anymore (was deleted by another user) :)

    let $node-to-move := collection($config:data-root)//id($resourceId)

    return switch ($direction)
       case 'left' return 
            let $positionNode := $node-to-move/preceding-sibling::*[1]
            let $foo := update insert $node-to-move preceding $positionNode 
            let $bar := update delete $node-to-move
            return map { 'operation': 'move','success': "true"}
       case 'right' return 
            let $positionNode := $node-to-move/following-sibling::*[1]
            let $foo := update insert $node-to-move following $positionNode
            let $bar := update delete $node-to-move
            return map {'operation': 'move','success': "true"}
       default return map {'operation': 'move','success': "false"}
};




(:create a new module of the type @type. Return html-module-list including new module:)
declare function admin:createModule($type as xs:string?) {
            let $configFile := doc($config:app-root || "/data/modules/config.xml")
            let $config := $configFile/contents
            let $moduleXML := util:deep-copy(doc($config:app-root || "/config/modules-config-default.xml")//module[./type/text() = $type][1])
            (:create a unique ID for the new module and put it into config.xml:)
            let $moduleID := admin:createUniqueID($type)
            let $moduleWithId := functx:add-attributes($moduleXML, xs:QName('xml:id'), $moduleID)
            
            let $insert := update insert $moduleWithId into $config
            let $IDattribute := update insert attribute xml:id {$moduleID} into $config/module[last()]
            
            (: create a new folder for the module with the name of the module's id:)
            let $newCollection := xmldb:create-collection($config:app-root || "/data/modules/",$moduleID)
            (: copy the type specific default icon into the new module-folder and rename it:)
            let $copyDefaultIcon := xmldb:copy-resource($config:app-root || "/resources/icons/", concat('default_mod_',$type,'.png'), $newCollection, concat('default_mod_',$type,'.png'))
            (:xmldb:copy($config:app-root || "/resources/icons/", $newCollection , concat('default_mod_',$type,'.png')):)
            let $renameIcon := xmldb:rename($newCollection,concat('default_mod_',$type,'.png'),"module-icon.png")
            (:add a new default config.xml to $newCollection:)
            let $emptyConfig := if ($type="library") then doc($config:app-root || "/config/library-config-default.xml") else doc($config:app-root || "/config/collections-config-default.xml")
            let $createConfig := xmldb:store($newCollection,"config.xml",$emptyConfig)
           
            let $label := admin:unifyLabel($configFile, $moduleWithId/label/text(), $moduleID)
            let $updateLabel := update value  $config/id($moduleID)/label[1] with $label
        
            
            let $newURL := admin:createURLIdentifier($label)
            let $updateURLlabel := update insert <urllabel>{$newURL}</urllabel> into $config/id($moduleID)
            
            let $newModule :=  $config/id($moduleID)
            (:url might have to go back to mw:getAbsoluteURLpath($moduleID):)
            return map{
                    'success'       :       'true',
                    'operation'     :       'createModule',
                    'id'            :       $moduleID,
                    'label'         :       $newModule/label[1],
                    'urllabel'      :       $newModule/urllabel[1],
                    'url'           :       mw:getRelativeURLpath($moduleID),
                    'description'   :       $newModule/description[1],
                    'type'          :       $type
            }

};




(:this function ensures the passed label does not occur multiple times on the same folder level. Each resource (within the same level)
must have a unique name, in order to address resources correctly. If the resource label is changed to an already existing label, a number
(_2, _3...) is added and the function is called again, until a new label is found:)
declare function admin:unifyLabel($configFile as document-node(), $label as xs:string, $currentId as xs:string) as xs:string* {
        
        (:count how often the same label (url-encoded) exists on the current folder level. the current label itself is excluded from the count :)
        (:TODO: should be replaced by id() function :)
        let $labelCount := count($configFile//label[not(parent::*/@xml:id = $currentId) and admin:createURLIdentifier(./text())=admin:createURLIdentifier($label)])
        
        return if ($labelCount > 0) 
        then (
                let $label_endNum := functx:substring-after-last($label,'_')
                let $done := if (functx:is-a-number($label_endNum)) then (  
                                    concat( functx:substring-before-last($label,"_") ,  "_"  ,number($label_endNum)+1)
                                ) else (concat($label,'_2'))
                return admin:unifyLabel($configFile,  $done, $currentId)
        
        )
        else ($label)
};



(:takes the label (resource name), camel-cases and URL encodes it. This form of the label is used as the URL identifier (for the
resource. Note, that the URL-label must be unique on each folder-level. this is not ensured here, but in admin:unifyLabel():)
declare function admin:createURLIdentifier($label as xs:string) as xs:string* {
    let $labelToCamel := functx:words-to-camel-case($label)
    let $labelToURL := encode-for-uri($labelToCamel)
    return $labelToURL
};


(:recursive function to produce a new module-,collection-, or resource-id that is not yet in use:)
declare function admin:createUniqueID($prefix as xs:string?){
    let $testId := concat($prefix,"-",fn:tokenize(util:uuid(),'-')[1])
    let $idExist := collection($config:data-root)//id($testId)
    return if ($idExist) then ( admin:createUniqueID($prefix) ) else $testId 
};


declare function admin:storeFacsZone($resourceId as xs:string?,$elementId as xs:string?,$x as xs:string?,$y as xs:string?,$width as xs:string?,$height as xs:string?,$rotate as xs:string?){
    let $a := "aha"
    let $colPath :=concat(mw:getCollectionPathById($resourceId),'/mapping.xml')
    let $mappingFile := doc($colPath)
    
    let $newZone := <zone transcript="{$resourceId}" elementId="{$elementId}" x="{$x}" y="{$y}" height="{$height}" width="{$width}" rotate="{$rotate}"/>
                    
                    
    
    let $overwrite := if ($mappingFile//zone[@elementId=$elementId]) then (update replace $mappingFile//zone[@elementId=$elementId][1] with $newZone)
    else (update insert $newZone into $mappingFile//zoneMap[1])
    
    return map{
            'operation'     :       'storeFacsZone',
            'success'       :       "false",
            'resource'      :       $resourceId,
            'elementId'     :       $elementId,
            'x'             :       $x,
            'y'             :       $y,
            'width'         :       $width,
            'height'        :       $height,
            'rotate'        :       $rotate
            }
};


declare function admin:changeCSSvar($itemId as xs:string?, $value as xs:string?){
    let $settingsFile := doc($config:app-root||"/config/GeneralSettings.xml")//id($itemId)
    
    return if ($settingsFile)
        then 
            let $type := $settingsFile/data(@type)
            (:let $updateValue := if($type = "color") then concat("#",substring($value, 1, 6)) else $value:)
            let $oldVal := $settingsFile/text()||""
            let $updateVariable := if($value) then update value $settingsFile with $value else false()
            return map{
               'operation' : 'changeCSSvar',
               'success'   : 'true',
               'cssVar-itemId' : $itemId,
               'cssVar-type' :$type,
               'oldValue': $oldVal,
               'newValue': $settingsFile/text()
            }
        else map{
               'operation' : 'changeCSSvar',
               'success'   : 'false',
               'cssVar-itemId' : $itemId,
               'oldValue': "",
               'newValue': ""
            }
};

