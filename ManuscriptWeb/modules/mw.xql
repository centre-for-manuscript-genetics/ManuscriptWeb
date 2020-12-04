xquery version "3.1";

module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:import module namespace functx = "http://www.functx.com" at "/db/system/repo/functx-1.0.1/functx/functx.xq";:)
import module namespace functx="http://www.functx.com"; 
import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "config.xqm";
(:import module namespace mem-op="http://maxdewpoint.blogspot.com/memory-operations" at "mem-op.xql";:)
import module namespace mem-op="http://maxdewpoint.blogspot.com/memory-operations" at "/db/apps/XQuery-XML-Memory-Operations-master/memory-operations-pure-xquery.xqy";
import module namespace library ="http://exist-db.org/apps/ManuscriptWeb/library" at "library.xql";

declare function mw:getTranscriptIdFromResourceId($resourceId as xs:string?){
    let $folderpath := mw:getCollectionPathById($resourceId)
    let $mappingFile := doc($folderpath||"/mapping.xml")//transcriptSequence/transcript[1]/data(@xml:id)
    return $mappingFile
};


(:get the root element of the transcript for a given transcript ID:)
declare function mw:getTranscriptRoot($transcriptId as xs:string?){
    let $transcriptFilename := collection($config:data-root)//id($transcriptId)/data(@ref)
    let $transcript := doc(util:collection-name(collection($config:data-root)//id($transcriptId)) || "/transcripts/" || string($transcriptFilename))
    return $transcript

};

(:returns transcript fragments for the transcript with the ID $... from the node $fromId to the node $toId :)
declare function mw:getTranscript($resourceId as xs:string?, $pageNum as xs:string?, $fromId as xs:string?, $toId as xs:string?,$fullDoc as xs:boolean?){
    let $pageNum := if(functx:is-a-number($pageNum) and xs:int($pageNum) > 0) then $pageNum else "1"
    let $transcript :=  mw:getTranscriptRoot($resourceId)  
    let $countPB := count($transcript//tei:pb)
    let $countDivPage := count($transcript//tei:div[@type="page"])
    let $paginationType := if ($countPB = 0 and $countDivPage = 0) then "none" else
                            if ($countDivPage > $countPB) then "div" else "pb"
                            
    let $transcriptHidden := collection($config:data-root)//id($resourceId)/data(@hideTranscript)
    
    return map{
        "operation" : "getTranscript",
        "success" : "true",
        "pbCount" : $countPB,
        "divPageCount" : $countDivPage,
        "paginationType" : $paginationType,
        "tsHidden": $transcriptHidden,
        "pageNum" : 
                    if ($paginationType = "none" or $fullDoc = true()) then "all" 
                    else if ($paginationType = "pb") then fn:min((xs:int($pageNum),$countPB))
                    else fn:min((xs:int($pageNum),$countDivPage)) ,
        "data" :  
        
                if($transcriptHidden = "true") then <p>The transcript for the page you selected is missing or currently hidden.</p> 
                else if ($paginationType = "none" or $fullDoc = true()) then $transcript
                else if ($paginationType = "pb") then 
                        let $start := ($transcript//tei:pb)[xs:int($pageNum)]
                        (:the end is either the next linebreak or the end of the document:)
                        let $end := if (count($transcript//tei:pb) > xs:int($pageNum)) then $start/following::tei:pb[1] else $start/following::*[last()]
                        let $page := mw:trim-node($start,$end) (:util:get-fragment-between($start,$end, false(), false() ):) 
                        (:in memory: copy $page, insert the teiHeader before the tei:text element, execute the operation:)
                        let $copy := mem-op:copy($page)
                        let $full := mem-op:execute(mem-op:insert-before($copy, $page//tei:text,  $transcript//tei:teiHeader  ))
                        return 
                            $full
                    else 
                        let $start := $transcript//tei:div[@type="page"][fn:min((xs:int($pageNum),$countDivPage))]
                        let $page := mw:trim-node($start,$start) (:util:get-fragment-between($start,$end, false(), false() ):) 
                        (:in memory: copy $page, insert the teiHeader before the tei:text element, execute the operation:)
                        let $copy := mem-op:copy($page)
                        let $full := mem-op:execute(mem-op:insert-before($copy, $page//tei:text,  $transcript//tei:teiHeader  ))                        
                        return 
                            $full
                      ,
          "resource": $resourceId,
          "nAttribute" : if($paginationType = "none") then ""
                        else if ($paginationType ="pb") then
                           ($transcript//tei:pb)[xs:int($pageNum)]/data(@n)   
                        else
                           $transcript//tei:div[@type="page"][fn:min((xs:int($pageNum),$countDivPage))]/data(@n)
       }
};


(:returns the path to a collection of a given resource Id. a resource id can be a module, collection or document ID as defined
in the regarding config.xml:)
declare function mw:getCollectionPathById($resId as xs:string?) {
    let $els := collection($config:data-root)//id($resId)
    let $resourceFolder := concat(util:collection-name($els),'/',$resId)
    
    return $resourceFolder
};


(:return the URL label for a given resource id. ID's are unique within a MW instance, therefore the urllabel is easy to find:)
declare function mw:getURLlabel($resourceId as xs:string) as xs:string*{
    let $URLlabel := collection($config:data-root)//id($resourceId)/urllabel/text()
    return $URLlabel
};

(:return the resource-title for a given resource id. ID's are unique within a MW instance, therefore the urllabel is easy to find:)
declare function mw:getResourceLabel($resourceId as xs:string) as xs:string*{
    let $URLlabel := collection($config:data-root)//id($resourceId)/label/text()
    return $URLlabel
};

(:returns the id of the parent collection for a given collection id :)
declare function mw:getParentCollectionId($resId as xs:string?){
    let $path := substring-after(mw:getCollectionPathById($resId), 'modules')
    let $el := functx:substring-after-last(functx:substring-before-last($path,"/"),"/")
    
    return $el
};


(:get the path of url-labels relative to the data root. This path is not the physical folder-path in the db! to get the physical path use mw:getCollectionPathById():)
declare function mw:getRelativeURLpath($resourceId as xs:string) as xs:string*{
     (:let $test := util:collection-name(collection($config:data-root)//id($resourceId)):)
     
     let $idPath := substring-after(mw:getCollectionPathById($resourceId),"/modules/")
     let $tokenizedPath := fn:tokenize(functx:trim($idPath), '/')
     let $URLlabels := for $element in $tokenizedPath return mw:getURLlabel($element)
     let $done := fn:string-join($URLlabels,"/")
     return "/Modules/"||$done
     
     (:fn:string-join(
     for $segId at $p in $tokenizedPath return if(functx:all-whitespace(mw:getURLlabel(functx:trim($segId)))) then () else (concat(mw:getURLlabel($segId),'/')), '')
     :)
     
};


(:TODO: replace this function! it is a runtime killer!:)
declare function mw:getAbsoluteURLpath($resourceId as xs:string) as xs:string*{
    let $pathEnd := mw:getRelativeURLpath($resourceId)
    let $toString := string-join($pathEnd)
   (: return (concat($config:absolutePath,"/",$toString)):)
    return (concat("/",$toString))
};

(:TODO: rename this function and document it better!!:)
(:recursive function, that cuts of the "first" urlidentifier of the path, retrieves the corresponding ID:)
declare function mw:runIntoFolder($remainingPath as xs:string?, $nextId as xs:string?){
    (:remove leading slash, if present:)
    let $remainingPath := if (starts-with($remainingPath,'/')) then (substring($remainingPath, 2)) else ($remainingPath)
    (:removing ending slash if present:)
    let $remainingPath := if (ends-with($remainingPath,'/')) then (functx:substring-before-last($remainingPath, '/')) else ($remainingPath)
    
    
    (:current config file is either the module-config file, or the config file of the next folder-level:)
    let $currentConfigFile := if (functx:all-whitespace($nextId)) then ("/db/apps/ManuscriptWeb/data/modules/config.xml") else (concat(mw:getCollectionPathById($nextId),'/config.xml')) 
    
    
    let $currentURLLabel := if (contains($remainingPath,'/')) then substring-before($remainingPath,'/') else $remainingPath
    let $remainingPath := substring-after($remainingPath, '/')
    
    let $upcomingId := data(doc($currentConfigFile)//*[child::urllabel=$currentURLLabel][1]/@xml:id)
    
    return if (not(functx:all-whitespace($remainingPath))) then (mw:runIntoFolder($remainingPath,$upcomingId)) else ($upcomingId)
    (:return $currentConfigFile:)
    

};

(:get the id of the parent mw-module for a given resource by the resource id :)
declare function mw:getModuleId($resourceId as xs:string) as xs:string*{
    let $parentId := mw:getParentCollectionId($resourceId)
    return if (not(functx:all-whitespace($parentId))) then (mw:getModuleId($parentId)) else ($resourceId)
};

(:get the id of the parent mw-module for a given node:)
(:Todo: get from document-uri to module-id via path?
declare function mw:getModuleId($node as node()) as xs:string*{
    document-uri( root($node))
};
:)

(:get the type ("","","","") of a given module by its resource-ID. Only works on modules!:)
declare function mw:getModuleType($resourceId as xs:string) as xs:string*{
    let $configFile := doc("/db/apps/ManuscriptWeb/data/modules/config.xml")
    let $moduleId := mw:getModuleId($resourceId)
    let $type := $configFile//id($moduleId)/type[1]
    return $type
};

(:returns the type of a resource. Possible types are "module", "collection" and "document":)
declare function mw:getResourceType($resourceId as xs:string) as xs:string*{
    let $type := collection($config:data-root)//id($resourceId)/name(.)
    return $type
};



(:transformation --> SHOULD BE REPLACED BY A CETEI APPROACH:)
declare function mw:tei2html(){
    let $doc := doc(concat($config:data-root, '/test/NLI4.xml'))
    let $xsl := doc("/db/apps/ManuscriptWeb/resources/xslt/TEI2HTML/html/html.xsl")

    
    return $doc
    
};


(:returns a zone (rectangle) four a given element on a given resource:)
declare function mw:getFacsZone($resourceId as xs:string?,$elementId as xs:string?){
    let $colPath :=concat(mw:getCollectionPathById($resourceId),'/mapping.xml')
    let $mappingFile := doc($colPath)
    
    let $zone := $mappingFile//zone[@elementId=$elementId]
                    
    
    return map{
            'operation'     :       'getFacsZone',
            'success'       :       "true",
            'resource'      :       data($zone/@transcript),
            'elementId'     :       data($zone/@elementId),
            'x'             :       data($zone/@x),
            'y'             :       data($zone/@y),
            'width'         :       data($zone/@width),
            'height'        :       data($zone/@height),
            'rotate'        :       data($zone/@rotate)
            }
};

(:TODO: phrase level ID's are not unique (one document can have multiple different transcripts that use the same ids). 
therefore $resourceID (for the transcript-id!) must be passed, too! For now $a[1] is transformed (first found id):)
declare function mw:getZoneTranscript($elementId as xs:string?){
    let $a := collection($config:data-root)//id($elementId)
    
    let $xsl := doc("/db/apps/ManuscriptWeb/data/transformations/notes.xsl")
    let $result := transform:transform($a[1], $xsl,(<parameters/>))
    
    return $result
};

(:returns all zones captured for a given facsimile:)
declare function mw:getFacZones($facsimileId as xs:string?){
    let $allZones := collection($config:data-root)//zone[@facsimileId=$facsimileId]
    
    let $a := for $zone in $allZones
                    let $elementId := data($zone/@elementId)
                    let $text := mw:getZoneTranscript($elementId)
                    return map{
                        'resource'      :       data($zone/@transcript),
                        'elementId'     :       data($zone/@elementId),
                        'facsimileId'   :       data($zone/@facsimileId),
                        'x'             :       data($zone/@x),
                        'y'             :       data($zone/@y),
                        'width'         :       data($zone/@width),
                        'height'        :       data($zone/@height),
                        'rotate'        :       data($zone/@rotate),
                        'text'          :       $text
                    
                    }

    return map { 
            'operation'     :       'getFacsZone',
            'success'       :       "true",
            'data'          :       $a
            }   
};



(:GENETIC GRAPH VIEWER:)

declare function mw:getGenGraph($entrypoint){
    let $incoming := mw:getIncomingRelList($entrypoint)(:mw:getIncomingDocRelations($entrypoint):)
    let $outgoing := mw:getOutgoingRelList($entrypoint) (:mw:getOutgoingDocRelations($entrypoint):)
    
    let $resourceType := mw:getResourceType($entrypoint)
    let $contextdocLabel := if($resourceType = "item") then library:item_getShortTitle($entrypoint)  else  collection($config:data-root)//id($entrypoint)//label/text()
    
    let $docPath := mw:getCollectionPathById($entrypoint) 
    
    return map {
        
        'operation' :   'getGenGraph',
        'success'   :   'true',
        'resourceType' :    $resourceType,
        'resource'  :   $entrypoint,
        "context": map {
                        "docId": $entrypoint,
                        "docType" : $resourceType,
                        "docLabel" : $contextdocLabel,
                        "phraseid" : "",
                        "shownurl" : mw:getRelativeURLpath($entrypoint),
                        "docPath": $docPath
                    },
        'incomingDocLevel'  : $incoming,
        'outgoingDocLevel'  : $outgoing
    }

};

declare function mw:getIncomingRelList($entrypoint){
    let $relations := collection($config:data-root)//relation[to/@docId=$entrypoint]
    for $relation in $relations
        group by $from:= data($relation/from/@docId)
        let $n:= count($relations//from[@docId=$from])
        let $docType := mw:getResourceType($from)
        let $docLabel := if($docType = "item") then library:item_getShortTitle($from)  else  collection($config:data-root)//id($from)//label/text()
        let $docPath := mw:getCollectionPathById($from)
        
        return map {
            "docId": $from,
            "countRel": $n,
            "docType": $docType,
            "docLabel": $docLabel,
            "docPath": $docPath,
            "shownurl" : mw:getRelativeURLpath($from)
        }
};

declare function mw:getOutgoingRelList($entrypoint){
    let $relations := collection($config:data-root)//relation[from/@docId=$entrypoint]
    for $relation in $relations
        group by $to:= data($relation/to/@docId)
        let $n:= count($relations//to[@docId=$to])
        let $docType := mw:getResourceType($to)
        let $docLabel := if($docType = "item") then library:item_getShortTitle($to)  else  collection($config:data-root)//id($to)//label/text()
        let $docPath := mw:getCollectionPathById($to)
        
        return map {
            "docId": $to,
            "countRel": $n,
            "docType": $docType,
            "docLabel": $docLabel,
            "docPath": $docPath,
            "shownurl" : mw:getRelativeURLpath($to)
            
        }
};


(:deprecated, super slow and retrieves all individual relations where only groups are needed (remove soon, 17.07.2019):)
declare function mw:getIncomingDocRelations($entrypoint){
    let $relations := collection($config:data-root)//relation[to/@docId=$entrypoint]
    
    for $incoming in $relations
        let $fromDocId := data($incoming/from/@docId)
        let $docType := mw:getResourceType($fromDocId)
        let $fromDocLabel := if($docType = "item") then library:item_getShortTitle($fromDocId)  else  collection($config:data-root)//id($fromDocId)//label/text()
        let $docPath := mw:getCollectionPathById($fromDocId)
        return 
            map {
                    "relationId" : data($incoming/@xml:id),
                    "from": map {
                        "docid": $fromDocId,
                        "docType" : $docType,
                        "doclabel" : $fromDocLabel,
                        "phraseid" : data($incoming/from/@phraseId),
                        "shownurl" : mw:getRelativeURLpath($fromDocId),
                        "picPath" : $docPath
                    }
            }
};

(:deprecated, super slow and retrieves all individual relations where only groups are needed (remove soon, 17.07.2019):)
declare function mw:getOutgoingDocRelations($entrypoint){
    let $relations := collection($config:data-root)//relation[from/@docId=$entrypoint]
    
   
    for $incoming in $relations
        let $toDocId := data($incoming/to/@docId)
        let $docType := mw:getResourceType($toDocId)
        let $toDocLabel := $toDocId (:if($docType = "item") then library:item_getShortTitle($toDocId)  else  collection($config:data-root)//id($toDocId)//label/text():)
        let $docPath := mw:getCollectionPathById($toDocId)
        return 
            map {
                    "relationId" : data($incoming/@xml:id),
                    "to": map {
                        "docid": $toDocId,
                        "doctype" : $docType,
                        "doclabel" : $toDocLabel,
                        "phraseid" : data($incoming/to/@phraseId),
                        "shownurl" : mw:getRelativeURLpath($toDocId),
                        "picPath" : $docPath
                    }
            }
};


(:get the config.xml file with a given resourceID :)
declare function mw:getConfigFileFromId($resourceId){
    let $confFile := if (mw:getResourceType($resourceId) = "doc") then "/mapping.xml" else "/config.xml"
    return
        doc(util:collection-name(collection($config:data-root)//id($resourceId)) || "/"|| $resourceId || $confFile)
};

(:THESE ONES ARE NEEDED BECAUSE THE JAVA VERSION util:get-fragment-between() IS CURRENTLY BUGGY:)
(: TODO: replace and remove as soon as issue is resolved.:)

(:~  trim the XML from $nodes $start to $end 
 :   The algorithm is 
 : 1) find  all the ancestors of the start node - $startParents
 : 2) find  all the ancestors of the end node- $endParents
 : 3) recursively, starting with the common top we create a new element which is a copy of the element being trimmed by 
 :    3.1 copying all attributes 
 :    3.2 there are four cases depending on the node and the start and end edge nodes of the tree
 :     a) left and right nodes are the same - nothing else to copy
 :     b) both nodes are in the node's children - trim the start one, copy the intervening children and trim the end one
 :     c) only the start node is in the node's children - trim this node and copy the following siblings
 :     d) only the end node is in the node's children  - copy the preceding siblings and trim the node
 :    attributes (currently in the fb namespace since its not a TEI attribute) are added to trimmed nodes  
 : @param start  - the element bounding the start of the subtree
 : @param end - the element bounding the end of the subtree
:)

declare function mw:trim-node($start as node() ,$end as node()) {
    let $startParents := $start/ancestor-or-self::*
    let $endParents := $end/ancestor-or-self::*
    let $top := $startParents[1]
    return
       mw:trim-node($top,subsequence($startParents,2),subsequence($endParents,2))
};

declare function mw:trim-node($node as node(), $start as node()*, $end as node()*) {
       if (empty($start) and empty($end)) 
       then $node                                                       (: leaf is untrimmed :)
       else 
          let $startNode := $start[1]
          let $endNode:= $end[1]
          let $children := $node/node()
          return
             element {QName (namespace-uri($node), name($node))} {       (: preserve the namespace :)
              $node/@* ,                                                 (: copy all the attributes :)
              if ($startNode is $endNode)                                (: edge node  is common :)
              then mw:trim-node($startNode, subsequence($start,2),subsequence($end,2))
              else 
              if ($startNode = $children and $endNode = $children)       (: both in same subtree :)
              then (mw:trim-node($startNode, subsequence($start,2),()),  (: first the trimmed start node :)
                                                                         (: then the siblings between start and end nodes :)                                                                     
                    $startNode/following-sibling::node() 
                           except $endNode/following-sibling::node() 
                           except $endNode,
                    
                    mw:trim-node($endNode, (), subsequence($end,2))      (: then the trimmed end node :)      
                   )
              else if ($startNode = $children)                           (: start node is in the children :)
              then 
                 ( mw:trim-node($startNode, subsequence($start,2),()),  (: first the trimmed start node :)
                   $startNode/following-sibling::node()                 (: then  the following siblings :)
                 )
              else if ($endNode = $children)                            (: end node is in the children :)
              then 
                 (  $endNode/preceding-sibling::node(),                  (: the preceding siblings :)
                    mw:trim-node($endNode, (), subsequence($end,2))      (: then the trimmed end node :)              
                 )
              else ()      
            }
};


(:get all Notebook documents:)
declare function mw:getNotebookTS(){
    let $nbs := doc(concat($config:data-root, "/modules/config.xml"))//module[type/text() ="notes"]/data(@xml:id)
    for $nb in $nbs
        return collection(concat($config:data-root, "/modules/",$nb))//tei:TEI
    (:dann: iteriere drüber, für jeden, return das tei:TEI:)

};


(:get all Draft documents:)
declare function mw:getDraftTS(){
    let $drafts := doc(concat($config:data-root, "/modules/config.xml"))//module[type/text() ="drafts"]/data(@xml:id)
    for $draft in $drafts
        return collection(concat($config:data-root, "/modules/",$draft))//tei:TEI
};


declare function mw:getDocumentIdFromTSNode($node as node()){
    let $doc := base-uri($node)
    return tokenize(substring-before($doc,"/transcripts/"),"/")[last()]

};



(:adds the css variables from the configuration file to any requested css file:)
declare function mw:process-css($requestedFile as xs:string?){
    let $cssFile := util:binary-to-string(util:binary-doc($config:app-root||"/"||$requestedFile))
    let $configVars := doc($config:app-root||"/config/GeneralSettings.xml")//CSSvar
    let $collectVars := for $var in $configVars return "--"||$var/data(@xml:id) || ": " || $var/text()||";&#xa;"
    let $mime-type := "text/css; charset=UTF-8"
    let $filename := functx:substring-after-last($requestedFile,"/")
    let $dataResponse := util:base64-encode(":root {&#xa;"|| string-join($collectVars) || "}&#xa;" || $cssFile)
    
    return response:stream-binary($dataResponse,$mime-type,$filename)
};

