xquery version "3.1";

module namespace viewstuff = "http://exist-db.org/apps/ManuscriptWeb/fun";

declare namespace request = "http://exist-db.org/xquery/request";

(:import module namespace functx = "http://www.functx.com" at "/db/system/repo/functx-1.0/functx/functx.xql";:)
import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "config.xqm";
import module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw" at "mw.xql";





declare function viewstuff:loadingSpinner($mytext as xs:string?){
    <div>
        <div class="sk-cube-grid">
            <div class="sk-cube sk-cube1"></div>
            <div class="sk-cube sk-cube2"></div>
            <div class="sk-cube sk-cube3"></div>
            <div class="sk-cube sk-cube4"></div>
            <div class="sk-cube sk-cube5"></div>
            <div class="sk-cube sk-cube6"></div>
            <div class="sk-cube sk-cube7"></div>
            <div class="sk-cube sk-cube8"></div>
            <div class="sk-cube sk-cube9"></div>
        </div>
        <div class="sk-cube-caption">Loading {$mytext}...</div>
     </div>
};


(: TODO: delete... probably not used aynmore!
declare function viewstuff:document-facsimileview($resource as xs:string?){
    let $a := "..."
    return
    <div id="thatDeck" class="row">
        {viewstuff:show-facsimile-thumbnails($resource)}
    </div>
};:)

(:show individual document (in non-library module) --> not used anymore! this thumbnail view looked bad. replaced by image viewer! :)
(:declare function viewstuff:show-facsimile-thumbnails($resource as xs:string?){

    let $collectionPath := mw:getCollectionPathById($resource)
    let $configuration := doc($collectionPath ||'/mapping.xml' )//imageSequence/image
    
    
    
    let $thumbnailFolder := $collectionPath || "/facsimiles/thumbs"

    

    (:access rights for the given resource:)
    let $canSee := sm:has-access($thumbnailFolder, "r")
    let $canEdit := sm:has-access($thumbnailFolder, "w")
    let $isAdmin := sm:is-dba(sm:id()//sm:real/sm:username)
    let $isOwner := data(sm:get-permissions($thumbnailFolder)//sm:permission/@owner)=  sm:id()//sm:real/sm:username
    
   
    for $image in $configuration
        let $internalResourceId := $image/@xml:id
        let $imagePath := $thumbnailFolder|| "/" || data($image/@ref)
        let $canSee := sm:has-access($imagePath, "r")
        return if ($canSee) then 
        
             <div class="col-12 col-sm-4 col-md-3 col-lg-2 module-tile resource-tile" data-resourceId="{$internalResourceId}">
                <div id="{$internalResourceId}" class="card clickable facsimile-link" data-explorerurl="" data-shownurl="">
                    <div class="card-header-wrapper">
                        <!-- todo: don't load default icon here, but its copy in the regarding folder!-->
                        <img class="card-img-top" src="{replace($imagePath,'/db','/exist')}" alt="Card image cap"/>
                    </div>
                    <div class="card-body">
                            <h5 class="card-title {if($canEdit) then "editable-text pull-to-top" else ""}" data-nodeType ="label">{$image/label/text()}</h5>
                    </div>
                    <div class="card-footer">
                        { if ($canEdit or $isAdmin or $isOwner) then
                            <div class="settings-cardpanel-collection pull-to-top">
                                   <!-- todo: delete and share buttons can move into the settings panel! -->
                                   <!-- info button: on mouse over shows details about the document -->
                                   <button class="btn btn-mw-outline my-2 my-sm-0 icbtn ">
                                        <i class="fas fa-info fa-sm"/>
                                   </button>
                                   <!-- settings button: on click shows settings menu, e.g. to change icon or metadata --><button 
                                   class="btn btn-mw-outline my-2 my-sm-0 icbtn ">
                                       <i class="fas fa-wrench fa-sm"></i>
                                   </button>
                                   <!--delete button (only visible for dba and owner): opens an affirmation modal-->
                                   { if ($isAdmin or $isOwner) then 
                                       <button class="btn btn-mw-outline my-2 my-sm-0 icbtn collection-delete">
                                           <i class="fas fa-trash-alt fa-sm"/>
                                       </button> else ""}
                            </div>  else ""}
                    </div>
                </div>
            </div>
            
            
            
        else ""
};:)

declare function viewstuff:show-documents($entrypointId as xs:string?) {
    let $confpath := mw:getCollectionPathById($entrypointId)
    let $configuration := doc($confpath || '/config.xml')//contents/*[name() = "doc" or name() = "collection"]
    

    
    for $document at $p in $configuration
    let $type := $document/name()
    let $forwardFile := if ($type="doc") then "document-viewer.html" else "module-content.html"
    let $resourceFolder := concat($confpath, "/", data($document/@xml:id))
    let $docId := util:absolute-resource-id($document)
    let $internalResourceId := data($document/@xml:id)
    let $urllabel := $document/urllabel/text()
    
    (:access rights for the given resource:)
    let $canSee := sm:has-access($resourceFolder, "r")
    let $canEdit := sm:has-access($resourceFolder, "w")
    let $isAdmin := sm:is-dba(sm:id()//sm:real/sm:username)
    let $isOwner := data(sm:get-permissions($resourceFolder)//sm:permission/@owner) = sm:id()//sm:real/sm:username
    
    return
    
        if ($canSee) then
            <div id="theDocument" 
                class="col-sm-2 module-tile resource-tile"
                data-resourceId="{$internalResourceId}">
                <div
                    class="card clickable {
                            if ($type = "doc") then
                                "doc-card"
                            else
                                ""
                        }  explorer-link"
                    data-explorerurl="{$config:absolutePath || "/templates/" || $forwardFile || "?resource=" || $internalResourceId}"
                    data-shownurl="{mw:getRelativeURLpath($internalResourceId)}/"
                >
                    <div
                        class="card-header-wrapper">
                        <!-- todo: don't load default icon here, but its copy in the regarding folder!-->
                        <img
                            class="card-img-top"
                            src="{$config:absolutePath}/resources/icons/default_collection.png"
                            alt="Card image cap"/>
                    </div>
                    <div
                        class="card-body">
                        <h5
                            class="card-title {
                                    if ($canEdit) then
                                        "editable-text pull-to-top"
                                    else
                                        ""
                                }"
                            data-nodeType="label">{$document/label/text()}</h5>
                    </div>
                    <div
                        class="card-footer">
                        {
                            if ($canEdit or $isAdmin or $isOwner) then
                                <div
                                    class="settings-cardpanel-collection pull-to-top">
                                    <!-- todo: delete and share buttons can move into the settings panel! -->
                                    <!-- info button: on mouse over shows details about the document -->
                                    <button
                                        class="btn btn-mw-outline my-2 my-sm-0 icbtn resource-info">
                                        <i
                                            class="fas fa-info fa-sm"/>
                                    </button>
                                    <!-- settings button: on click shows settings menu, e.g. to change icon or metadata --><button
                                        class="btn btn-mw-outline my-2 my-sm-0 icbtn resource-info mod-edit">
                                        <i
                                            class="fas fa-wrench fa-sm"></i>
                                    </button>
                                    <!--delete button (only visible for dba and owner): opens an affirmation modal-->
                                    {
                                        if ($isAdmin or $isOwner) then
                                            <button
                                                class="btn btn-mw-outline my-2 my-sm-0 icbtn collection-delete">
                                                <i
                                                    class="fas fa-trash-alt fa-sm"/>
                                            </button>
                                        else
                                            ""
                                    }
                                </div>
                            else
                                ""
                        }
                    </div>
                </div>
            </div>
        else
            ()
      
};

(:
(:show all collections inside the given entrypoint. 
   the entrypoint can be either the ID of a module or of a collection :)
declare function viewstuff:show-collections($entrypointId as xs:string?) {
    (:get the resources config.xml and the corresponding data folder:)
    let $configuration := doc(concat(mw:getCollectionPathById($entrypointId), '/config.xml'))//collection
    
    (:for each collection within the given resource:)
    for $collection at $p in $configuration
    let $resourceFolder := concat(mw:getCollectionPathById($entrypointId), "/", data($collection/@xml:id))
    let $docId := util:absolute-resource-id($collection)
    let $internalResourceId := data($collection/@xml:id)
    
    (:access rights for the given resource:)
    let $canSee := sm:has-access($resourceFolder, "r")
    let $canEdit := sm:has-access($resourceFolder, "w")
    let $isAdmin := sm:is-dba(sm:id()//sm:real/sm:username)
    let $isOwner := data(sm:get-permissions($resourceFolder)//sm:permission/@owner) = sm:id()//sm:real/sm:username
    
    return
        if ($canSee) then
            
            <div
                class="col-sm-2 module-tile resource-tile"
                data-resourceId="{$internalResourceId}">
                <div
                    id="{$internalResourceId}"
                    class="card clickable explorer-link"
                    data-explorerurl="{$config:absolutePath}/templates/module-content.html?resource={$internalResourceId}"
                    data-shownurl="{mw:getRelativeURLpath($internalResourceId)}">
                    <div
                        class="card-header-wrapper">
                        <!-- todo: don't load default icon here, but its copy in the regarding folder!-->
                        <img
                            class="card-img-top"
                            src="{$config:absolutePath}/resources/icons/default_collection.png"
                            alt="Card image cap"/>
                    </div>
                    <div
                        class="card-body">
                        <h5
                            class="card-title {
                                    if ($canEdit) then
                                        "editable-text pull-to-top"
                                    else
                                        ""
                                }"
                            data-nodeType="label">{$collection/label/text()}</h5>
                    </div>
                    <div
                        class="card-footer">
                        <div
                            class="settings-cardpanel-collection pull-to-top">
                            <!-- todo: delete and share buttons can move into the settings panel! -->
                            <!-- info button: on mouse over shows details about the document -->
                            <button
                                class="btn btn-mw-outline my-2 my-sm-0 icbtn resource-info">
                                <i
                                    class="fas fa-info fa-sm"/>
                            </button>
                            <!-- settings button: on click shows settings menu, e.g. to change icon or metadata --><button
                                class="btn btn-mw-outline my-2 my-sm-0 icbtn resource-info mod-edit">
                                <i
                                    class="fas fa-wrench fa-sm"></i>
                            </button>
                            <!--delete button (only visible for dba and owner): opens an affirmation modal-->
                            {
                                if ($isAdmin or $isOwner) then
                                    <button
                                        class="btn btn-mw-outline my-2 my-sm-0 icbtn collection-delete">
                                        <i
                                            class="fas fa-trash-alt fa-sm"/>
                                    </button>
                                else
                                    ""
                            }
                        </div>
                    </div>
                </div>
            </div>
        else
            (<!--none-->)
};
:)



(:this function lists the modules as configured by the module-config.xml file:)
declare function viewstuff:show-modules() {
    let $module-conf := doc("/db/apps/ManuscriptWeb/data/modules/config.xml")//module
    for $module at $p in $module-conf
    let $resource := xs:anyURI(concat("/db/apps/ManuscriptWeb/data/modules/", data($module/@xml:id)))
    let $canSee := sm:has-access($resource, "r")
    let $canEdit := sm:has-access($resource, "w")
    let $isAdmin := sm:is-dba(sm:id()//sm:real/sm:username)
    let $isOwner := data(sm:get-permissions($resource)//sm:permission/@owner) = sm:id()//sm:real/sm:username
    let $docId := util:absolute-resource-id($module)
    let $internalResourceId := data($module/@xml:id)
    let $moduleType := $module/type/text()
    return
        if ($canSee) then
            (: return if (request:get-attribute("org.exist-db.ManuscriptWeb.user")) then :)
            <div
                class="col-sm-3 module-tile resource-tile"
                data-resourceId="{$internalResourceId}">
                <div
                    class="card clickable explorer-link"
                    data-explorerurl="{
                            
                            if ($moduleType = "library")
                            then
                                $config:absolutePath || "/templates/library-content.html?resource=" || $internalResourceId
                            else
                                $config:absolutePath || "/templates/module-content.html?resource=" || $internalResourceId
                        
                        }"
                    data-shownurl="{mw:getRelativeURLpath($internalResourceId)}">
                   
                   <div
                        class="card-header-wrapper">
                        <img
                            class="card-img-top"
                            src="{$config:absolutePath}/data/modules/{$internalResourceId}/module-icon.png"
                            alt="Card image cap"/>
                        {
                            if ($canEdit or $isAdmin or $isOwner) then
                                <div
                                    class="settings-cardpanel pull-to-top">
                                    <!--share button: opens the share and access panel-->
                                    <button
                                        class="btn btn-mw-outline my-2 my-sm-0 icbtn mod-edit">
                                        <i
                                            class="fas fa-wrench fa-sm"/>
                                    </button>
                                    <!--delete button (only visible for dba and owner): opens an affirmation modal-->
                                    {
                                        if ($isAdmin or $isOwner) then
                                            <button
                                                class="btn btn-mw-outline my-2 my-sm-0 icbtn mod-delete">
                                                <i
                                                    class="fas fa-trash-alt fa-sm"/>
                                            </button>
                                        else
                                            ""
                                    }
                                </div>
                            else
                                ""
                        }
                        {
                            if ($isAdmin) then
                                <div
                                    class="move-panel">
                                    <div
                                        class="move-panel-left pull-to-top">
                                        <button
                                            type="button"
                                            class="btn btn-mw-outline move-left pull-left"><i
                                                class="fas fa-arrow-left"></i></button>
                                    </div>
                                    <div
                                        class="move-panel-right pull-to-top">
                                        <button
                                            type="button"
                                            class="btn btn-mw-outline move-right pull-right"><i
                                                class="fas fa-arrow-right "></i>
                                        </button>
                                    </div>
                                </div>
                            else
                                ""
                        }
                    </div>
                    
                    <div
                        class="card-header">
                        <h4
                            class="card-title {
                                    if ($canEdit) then
                                        "editable-text pull-to-top"
                                    else
                                        ""
                                }"
                            data-nodeType="label">{$module/label/text()}</h4>
                    </div>
                    <div
                        class="card-body">
                        <!--check here, this can't work! make sure, nodetype is set as attribute, therefore don't pass doc-id and node-id!-->
                        <p
                            class="card-text {
                                    if ($canEdit) then
                                        "editable-text pull-to-top"
                                    else
                                        ""
                                }"
                            data-nodetype="description">{$module/description}</p>
                    </div>
                    
                    <div
                        class="card-footer">
                    </div>
                </div>
            </div>
        else
            ""
};



