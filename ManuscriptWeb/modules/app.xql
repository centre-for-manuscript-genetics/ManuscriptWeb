xquery version "3.1";

module namespace app="http://exist-db.org/apps/ManuscriptWeb/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://exist-db.org/apps/ManuscriptWeb/config" at "config.xqm";
import module namespace viewstuff="http://exist-db.org/apps/ManuscriptWeb/fun" at "view-functions.xql";
import module namespace mw ="http://exist-db.org/apps/ManuscriptWeb/mw" at "mw.xql";
import module namespace admin ="http://exist-db.org/apps/ManuscriptWeb/admin" at "admin.xql";

import module namespace functx="http://www.functx.com"; 

declare namespace tei="http://www.tei-c.org/ns/1.0";



declare function app:resourceMetadataForm($node as node(), $model as map(*), $entrypoint as xs:string?){
let $newDoc := admin:createDocument($entrypoint)
return
    <div class="col-sm-11">
        <form>
            <div class="form-group row ">
                <label for="docTitle" class="col-sm-3 col-form-label">Document Name:</label>
                <div class="col-sm-9">
                  <p type="text" class="editable-text" id="docTitle" data-nodetype="label" data-resourceid="{$newDoc/@xml:id}">{$newDoc//label/text()}</p>
                </div>
              </div>
              
              
             <div id="upload-panel" class="form-group row">
                <label class="col-sm-3 col-form-label">File Upload:</label>
                <div class="col-sm-9">
                    <div class="upload-drop-zone btn-block fileinput-button">
                        <span>Drop files here or click to browse your system for files. </span>
                    </div>
                    <!--the upload button is hidden and a click on the drag-and-dop div is redirected to this hidden button-->
                    <input id="fileupload" class="hiddenUploadButton" type="file" name="files[]" multiple="multiple" />
                    <!-- The global progress bar -->
                    <div id="progress" class="progress">
                        <div class="progress-bar progress-bar-success"></div>
                    </div>
                    <!-- The container for the uploaded files -->
                    <table id="files-table" class="files table table-striped">
                        <thead>
                            <tr>
                                <th>filename</th>
                                <th>folder</th>
                            </tr>
                        </thead>
                        <tbody id="files"></tbody>
                    </table>
                </div>
            </div>
              
              
            <div class="form-group row ">
                    <label for="staticEmail" class="col-sm-3 col-form-label col-form-label-sm" >
                        <div class="btn btn-mw-outline btn-sm" data-toggle="collapse" data-target="#collapseOne" aria-expanded="true" aria-controls="collapseOne">More Info</div>
                    </label>
              </div>
              <div class="collapse" id="collapseOne">
                  <div class="form-group row ">
                    <label for="moduleType" class="col-sm-3 col-form-label col-form-label-sm">Doc-Type:</label>
                    <div class="col-sm-9">
                      <input type="text" disabled="" readonly="" class="form-control form-control-sm" id="moduleType" placeholder="{
                            mw:getModuleType($entrypoint)
                      }-document"/>
                    </div>
                  </div>
                  <div class="form-group row "> 
                    <label for="resourceId" class="col-sm-3 col-form-label col-form-label-sm">Resource ID:</label>
                    <div class="col-sm-9">
                      <input type="text" disabled="" readonly="" class="form-control form-control-sm" id="resourceId" aria-describedby="ResIdHelp" placeholder="{$newDoc/@xml:id}"/>
                      <small id="ResIdHelp" class="form-text text-muted">The ID is only for internal use, it cannot be changed.</small>
                    </div>
                  </div>
                  <div class="form-group row">
                    <label for="resourceURL" class="col-sm-3 col-form-label col-form-label-sm">Resource URL:</label>
                    <div class="col-sm-9">
                      <input type="text" disabled="" readonly="" class="form-control form-control-sm" id="resourceURL" aria-describedby="ResUrlHelp" placeholder="~/{mw:getRelativeURLpath($entrypoint)}{$newDoc/urllabel/text()}"/>
                      <small id="ResUrlHelp" class="form-text text-muted">The URL is derived from the document name (camelcased and URL-encoded).</small>
                    </div>
                  </div>
              </div>  
        </form>
    </div>
};




(:this function lists the modules as configured by the module-config.xml file:)
declare function app:show-modules($node as node(), $model as map(*)) {
    viewstuff:show-modules()
};


declare function app:loadingSpinner($node as node(), $model as map(*),$mytext as xs:string?){
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


(:function wrapper to access show-documents via templating:)
declare function app:show-documents($node as node(), $model as map(*), $resource as xs:string?){
    viewstuff:show-documents($resource)
    
};

(:checks if a resource qualifies for IIIF image viewer/ has IIIF links :)
declare function app:has-IIIFsequence($resource as xs:string?){
    let $transcript := mw:getTranscriptRoot(mw:getTranscriptIdFromResourceId($resource))
    let $iiifCanvasCount := count($transcript//tei:surface[@type="iiif-canvas"])
    return if ($iiifCanvasCount > 0) then true() else false()
};

(: checks if a resource qualifies for text viewer / has a TEI transcript:)
declare function app:has-Transcript($resource as xs:string?){
    let $transcript := mw:getTranscriptRoot($resource)
    return if ($transcript) then true() else false()
};

(:dummy function for image viewer to get the id of the first transcript of a resource into image-viewer.html:)
declare function app:getTSIdDummy($node as node(), $model as map(*), $resource as xs:string?) {
   <div id="resIdDummy" data-res="{mw:getTranscriptIdFromResourceId($resource)}"/>
};

declare function app:show-document($node as node(), $model as map(*), $resource as xs:string?, $view as xs:string?, $imgnum as xs:string?){
    let $collectionPath := mw:getCollectionPathById($resource)
    
    
    (:If view is set to image,text or default, keep it, else check if there are images and text - and decide accordingly:)
    let $view := if ($view = "image" or $view = "text" or $view="default") then $view else 
                    if(not($view)) then "default" else
                        if ( app:has-IIIFsequence($resource)) then "image" else 
                             if (fn:exists(doc($collectionPath ||'/mapping.xml' )//transcriptSequence/transcript)) then "text" else "default"
    
    let $view := if ($view = "image" or $view = "default" and not(app:has-IIIFsequence($resource))) then "text" else $view
    
    let $imgnum := if (number($imgnum) and fn:exists(doc($collectionPath ||'/mapping.xml' )//imageSequence/image[number($imgnum)]) ) then number($imgnum) else 1
    
    
    
    return <div id="theDocument" data-resourceid="{$resource}" class="row no-gutters">
                {if ($view="image" or $view ="default") then 
                    <div id="imageViewField" data-resource="{$resource}" data-imgNum="{$imgnum}" class="col gutter-col">
                        {viewstuff:loadingSpinner("Image Viewer")}
                        <script type="text/javascript">
                            <!--
                                //load image here
                                var where = "#imageViewField";
                                var what = $(where).data("resource");
                                var imgnum = Number(new URL(window.location.href).searchParams.get("imgnum"));  
                                var numOrNull = (typeof imgnum === 'number' && isFinite(imgnum) && imgnum > 0 ) ? "&imgnum=" + imgnum : "";
                                $(where).load("$app/templates/image-viewer.html?resource=" + what + numOrNull);
                            -->
                        </script>
                    </div>
                else ""
                }
                {if ($view="text" or $view ="default") then 
                    <div id="textViewField" data-resource="{$resource}" class="col gutter-col">
                        {viewstuff:loadingSpinner("Text Viewer")}
                        <script type="text/javascript">
                            <!--
                                //load text here
                                var where = "#textViewField";
                                var what = $(where).data("resource");
                                $(where).load("$app/templates/text-viewer.html?resource=" + what);
                                //console.log("text to load from resource: "+$("#imageViewField").data("resource"));
                            -->
                        </script>
                    </div> else ""}
                
                
              
                {
                (:javascript for the split slider is only neccessary in split/default view!:)
                if ($view="default") then
                <script>
                    <!--
                      /* Have the textViewField and imageViewField resizable: JS here (uses split.js) */
                      var splitobj = Split(["#imageViewField","#textViewField"], {
                          elementStyle: function (dimension, size, gutterSize) { 
                              $(window).trigger('resize'); // Optional
                              return {'flex-basis': 'calc(' + size + '% - ' + gutterSize + 'px)'}
                          },
                          gutterStyle: function (dimension, gutterSize) { return {'flex-basis':  gutterSize + 'px'} },
                          sizes: [50,50],
                          minSize: 30,
                          gutterSize: 6,
                          cursor: 'col-resize'
                      });
                     -->
                </script> else ""}
                
                

           </div>
};




(:this function produces the module-selection for the "new module" modal from config/module-config-default:)
declare function app:new-modules($node as node(), $model as map(*)) {
    let $module-conf := doc("/db/apps/ManuscriptWeb/config/modules-config-default.xml")//module
    for $module at $p in $module-conf
        return 
        <div class="card" style="width: 30rem;">
            <a class="new-module" data-type="{$module/type}" data-toggle="modal" href="#moduleModal">
                <img class="card-img-top" src="{$config:absolutePath}/resources/icons/default_mod_{$module/type[1]}.png" alt="Card image cap"/>
                <div class="card-header"><h5 class="card-title">{$module/label}</h5></div>
            </a>
        </div>
};



(:return the +collection button, shown within modules and collections to add new collections inside, $resource is the id of the parent resource :)
declare function app:newCollectionButton($node as node(), $model as map(*), $resource as xs:string?){
    (:only show this button, if the currently logged in user has the right to write within the given resource (module/collection/file):)
    let $folder := mw:getCollectionPathById($resource)
    let $canRead := sm:has-access($folder, "w")
    return if ($canRead) then 
    <button class="btn btn-mw-std btn-sm float-right"   data-resource="{$resource}"  id="newCollectionBtn"><i class="far fa-plus-square"></i> collection</button>
    else ()
};

(:return the +document button, shown within collections to add documents, $resource is the id of the parent resource :)
declare function app:newDocumentButton($node as node(), $model as map(*), $resource as xs:string?){
    (:only show this button, if the currently logged in user has the right to write within the given resource (module/collection/file):)
    let $folder := mw:getCollectionPathById($resource)
    let $canRead := sm:has-access($folder, "w")
    return if ($canRead) then 
    <button class="btn btn-mw-std btn-sm float-right"   data-resource="{$resource}"  id="newDocumentBtn"><i class="far fa-plus-square"></i> document</button>
    else ()
};

(:return the +book button, shown within collections to add books, $resource is the id of the parent resource :)
declare function app:newBookButton($node as node(), $model as map(*), $resource as xs:string?){
    (:only show this button, if the currently logged in user has the right to write within the given resource (module/collection/file):)
    let $folder := mw:getCollectionPathById($resource)
    let $canRead := sm:has-access($folder, "w")
    return if ($canRead) then 
    <button class="btn btn-mw-std btn-sm float-right"   data-resource="{$resource}"  id="newBookBtn"><i class="far fa-plus-square"></i> title</button>
    else ()
};

(:make absolute Path available to JavaScript:)
declare function app:getJSPathVariable($node as node(), $model as map(*)){
    <script>var absolutePath = "{$config:absolutePath}"; </script>
};

(:~ +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 :+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 : the following functions are used for the top menu/navbar
 :+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 :+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 :)

(:return the "about" link for the navbar menu:)
declare function app:get-about-link($node as node(), $model as map(*)){
     <div class="nav-link explorer-link" data-shownurl="/About/" >About</div>
};


(:return the "about" link for the navbar menu:)
declare function app:get-cite-link($node as node(), $model as map(*)){
     <div class="nav-link explorer-link" data-shownurl="/Cite/">Cite</div>
};


(:returns the "modules"  for the navbar menu :)
(:produce a more dynamic version with sub-selections for the available modules!:)
declare function app:get-modules-link($node as node(), $model as map(*)){
    <div class="nav-link explorer-link" data-shownurl="/Modules/" >Modules</div>
};

(:returns the "chronoloy"  for the navbar menu :)
declare function app:get-chronology-link($node as node(), $model as map(*)){
    <div class="nav-link explorer-link"  data-shownurl="/Chronology/" >Chronology</div>
};

(:returns the ManuscriptWeb Logo on a "Home" link for the top menu:)
declare function app:get-home-logo($node as node(), $model as map(*)){
    <div class="navbar-brand explorer-link" data-shownurl="/Home/">
        <img src="{$config:absolutePath}/resources/icon.svg" width="80" class="d-inline-block align-top main-logo" alt=""/>
    </div>
};





(:~ +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 :+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 : the following functions provide the user-login functions
 :+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 :+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 :)

(:returns the full name of the current user, if given in the metadata, otherwise only username, otherwise "guest" :)
declare function app:username($node as node(), $model as map(*)) {
    (:let $user:= request:get-attribute("org.exist-db.ManuscriptWeb.user"):)
    let $user:= sm:id()//sm:real/sm:username/string()
    let $name := if ($user) then sm:get-account-metadata($user, xs:anyURI('http://axschema.org/namePerson')) else 'guest'
    return if ($name) then $name else $user
    
};

declare function app:getusername() {
    (:let $user:= request:get-attribute("org.exist-db.ManuscriptWeb.user"):)
    let $user:= sm:id()//sm:real/sm:username/string()
    let $name := if ($user) then sm:get-account-metadata($user, xs:anyURI('http://axschema.org/namePerson')) else 'guest'
    return if ($name) then $name else $user
    
};

declare 
    %templates:wrap
function app:userinfo($node as node(), $model as map(*)) as map(*) {
    (:let $user:= request:get-attribute("org.exist-db.ManuscriptWeb.user"):)
    let $user := sm:id()//sm:real/sm:username/string()
    let $name := if ($user) then sm:get-account-metadata($user, xs:anyURI('http://axschema.org/namePerson')) else 'Guest'
    let $group := if ($user) then sm:get-user-groups($user) else 'guest'
    return
        map { "user-id" : $user, "user-name" : $name, "user-groups" : $group}
};

(:~ +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 :+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 : the following functions are used for the document-viewer
 :+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 :+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 :)


(:transformation:)
declare function app:tei2html($node as node(), $model as map(*), $resource as xs:string?, $t as xs:string?, $page as xs:string?){
    let $t := if ($t) then xs:int($t) else 1
    let $page := if($page) then xs:int($page) else 1
    let $collectionpath := mw:getCollectionPathById($resource)
    let $transcpath :=  $collectionpath||'/transcripts'
    let $childResourcecs := xmldb:get-child-resources($transcpath)[$t]
    
    let $doc := doc($transcpath||'/'|| $childResourcecs)
    
    let $completePage := ($doc//tei:div[@type='page'])[$page]
    let $notelist := $completePage/tei:list/tei:item
    
    for $item in $notelist
        let $thisId := functx:trim($completePage/@xml:id)||"."||functx:trim(replace(replace(data($item/@n),'\(',''),'\)',''))
        let $isCaptured := if (doc($collectionpath||"/mapping.xml")//zone[@elementId=$thisId]) then true() else false()
        return <p class="notepar {if ($isCaptured) then 'rectDone' else ''}" id="{$thisId}" data-resId="{$resource}">
                    <span class="noteIdent">{data($item/@n)}</span>
                    <span class="noteText">{$item/text()}</span>
               </p>
    
};

declare function app:listTranscripts($node as node(), $model as map(*), $resource as xs:string?){
    let $facspath := mw:getCollectionPathById($resource)||'/facsimiles'
    let $transcpath := mw:getCollectionPathById($resource)||'/transcripts'

    let $childResourcecs := xmldb:get-child-resources($transcpath)
    
    for $filename in $childResourcecs
            let $title := if (doc($transcpath||'/'||$filename)//tei:title[1]) then doc($transcpath||'/'||$filename)//tei:title[1]/text() else ($filename)
            return <a class="dropdown-item" href="#" data-resourceid="{$resource}" data-filename="{$filename}">{$title}</a>
         
};

(:temporary load function for digfast student version! replace asap!:)
declare function app:loadImage($node as node(), $model as map(*), $resource as xs:string?, $t as xs:string?, $page as xs:string?){    
    let $t := if ($t) then xs:int($t) else 1
    let $page := if($page) then xs:int($page) else 1
    
    let $transcpath := mw:getCollectionPathById($resource)||'/transcripts'
    let $facspath := mw:getCollectionPathById($resource)||'/facsimiles'
    
    let $childResource := xmldb:get-child-resources($transcpath)[$t]
    let $doc := doc($transcpath||'/'|| $childResource)//tei:div[@type='page'][$page]
    let $facs := if ($doc/@facs)   
                    then $facspath||"/"||$doc/@facs 
                    else $facspath||"/"||$doc/@xml:id||".JPG"
    
    return if (util:binary-doc-available($facs)) then <img style="max-width:100%;" src="{replace($facs, '/db/apps', '')}"/> else "no image found"

};


(:################################################################################################################:)
(:################################################################################################################:)
(:##################             FUNCTIONS FOR FUTURE IMAGE/FACSIMILE MODULE                    ##################:)
(:################################################################################################################:)
(:################################################################################################################:)

declare 
    %templates:default("imgnum", "1")
function app:getDigFastZone($node as node(), $model as map(*), $facsimileid as xs:string?, $resource as xs:string?, $imgnum as xs:string?){
    let $facsimileid := if ($facsimileid) then $facsimileid else doc(mw:getCollectionPathById($resource) ||'/mapping.xml' )//imageSequence/image[xs:integer($imgnum)]/@xml:id
    
    let $imageName := collection($config:data-root)//id($facsimileid)
                      
    return if ($imageName) then 

    let $resourceFolder := util:collection-name($imageName)||"/facsimiles/"
    let $fileName := data($imageName/@ref)
    let $fullPath := $resourceFolder||$fileName
    
    let $preLoad := replace($fullPath, "/facsimiles","/facsimiles/thumbs")
    
    let $image := util:binary-doc($fullPath)
    let $height:= image:get-height($image)
    let $width := image:get-width($image)
    return 
        
                <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="dig_{$facsimileid}" class="digger" width="{$width}" height="{$height}">
      
                    <g class="scalingParent" id="scalingParent">
                        <image class="asyncImage" height="{$height}" width="{$width}"
                        data-href="{ if (util:binary-doc-available($fullPath)) then replace($fullPath, '/db/apps', '/exist/apps') else "" }"  
                        href="{ if (util:binary-doc-available($preLoad)) then replace($preLoad, '/db/apps', '/exist/apps') else "" }" x="0" y="0" visibility="visible"/>  
                    </g>
                    <filter id="blur-effect-1">
                        <feGaussianBlur stdDeviation="25" />
                    </filter>
                </svg> 
    else <div>The image you requested could not be found. {$facsimileid}</div>
    
};

(: TODO: remove this...

declare function app:getFacsimileById($facsimileId as xs:string, $size as xs:string){
    let $image := "hase"
    return 
        <div></div>
};

declare function app:getDocumentIdByFacsimileId($facsimileId as xs:string){
    let $image := "hase"
    return 
        <div></div>
};

declare function app:getModuleIdByFacsimileId($facsimileId as xs:string){
    let $image := "hase"
    return 
        <div></div>
};

:)


(:################################################################################################################:)
(:##################             END IMAGE/FACSIMILE MODULE FUNCTIONS                           ##################:)
(:################################################################################################################:)

(:this returns an svg canvas for the temporary student version. NOTE: the live version does not use this function anymore!
instead app:getDigFastZone is used!:)
declare function app:svgImage($node as node(), $model as map(*), $resource as xs:string?, $t as xs:string?, $page as xs:string?){
    let $t := if ($t) then xs:int($t) else 1
    let $page := if($page) then xs:int($page) else 1
    
    let $transcpath := mw:getCollectionPathById($resource)||'/transcripts'
    let $facspath := mw:getCollectionPathById($resource)||'/facsimiles'
    
    let $childResource := xmldb:get-child-resources($transcpath)[$t]
    let $doc := doc($transcpath||'/'|| $childResource)//tei:div[@type='page'][$page]
    let $facs := if ($doc/@facs)   
                    then $facspath||"/"||$doc/@facs 
                    else $facspath||"/"||$doc/@xml:id||".JPG"
                    
                    
    let $image := util:binary-doc($facs)
    let $height:= image:get-height($image)
    let $width := image:get-width($image)
    return
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="myCanvas" width="{$width}" height="{$height}">
            <g id="scalingParent">
                <image height="{$height}" width="{$width}" href="{replace($facs, '/db/apps', '/exist/apps')}" x="0" y="0" visibility="visible"/>  
            </g>
        </svg>
};

declare function app:pagination($node as node(), $model as map(*), $resource as xs:string?, $t as xs:string?, $page as xs:string?){
    let $t := if ($t) then xs:int($t) else 1
    let $page := if($page) then xs:int($page) else 1
    
    let $transcpath := mw:getCollectionPathById($resource)||'/transcripts'
    let $facspath := mw:getCollectionPathById($resource)||'/facsimiles'
    
    let $childResource := xmldb:get-child-resources($transcpath)[$t]
    let $doc := doc($transcpath||'/'|| $childResource)
    
    return
            <div class="input-group input-group-sm">
                <!-- these buttons will get functions via JS-->
                <div class="input-group-prepend">
                    <a class="btn btn-outline-secondary" href="?page={$page - 1 }" type="button">&lt;</a>
                </div>
                <input type="text" class="form-control col-sm-3" aria-label="Text input with checkbox" placeholder="{$page}"/>
                <div class="input-group-append">
                    <span class="input-group-text">/{count($doc//tei:div[@type="page"])}</span>
                    <a class="btn btn-outline-secondary" href="?page={$page+1}" type="button">&gt;</a>
                </div>
            </div>
            
            
           
};



(:declare
    %templates:wrap
function app:loadBooks($node as node(), $model as map(*)) as map(*) {
    let $log := util:log( 'debug', "sparta")
    let $allBooks := doc("../data/modules/library-369088f9/library_geert.xml")
  
    let $booksPerShelf := 5
    let $countShelfs := count($allBooks//book) div $booksPerShelf
    let $countShelfs := if ($allBooks mod $booksPerShelf = 0) then (count($allBooks) / $booksPerShelf) else ((count($allBooks) / $booksPerShelf) + 1)
    
    return map { "addresses" := collection($config:app-root || "/data/addresses")/address }
};:)


(:devide the selected books into shelf of 5 ($booksPerShelf) books. :)

declare
    %templates:wrap
function app:loadBooks($node as node(), $model as map(*), $resource as xs:string) as map(*) {
        (:TODO: get correct file by libraryid:)
   (: let $allBooks := doc($config:data-root || "/modules/library-369088f9/library_ijjs.xml")//book:)
    let $myBooks := doc($config:data-root || "/modules/"||$resource||"/config.xml")//items/item
    let $allBooks := for $x in $myBooks
                      order by $x/title[1]
                    return $x       
    
    let $booksPerShelf := 5
    let $countShelfs := if (count($allBooks) mod $booksPerShelf = 0) then (xs:int(count($allBooks) div $booksPerShelf)) else (count($allBooks) div $booksPerShelf + 1)
    
    return map { "books" :     for $x in (0 to ($countShelfs - 1))
                return  map{"soup" :  subsequence($allBooks, ($x * $booksPerShelf)+1 , $booksPerShelf)}
     }
};


declare function app:loadItem($node as node(), $model as map(*), $itemid as xs:string?)  {
    let $item := collection($config:data-root)//id($itemid)
    (:todo: put in as default values the correct text-nodes from $item:)
    return
    <form data-resourceid="{$itemid}">
        <div class="tab-content">
        
            <div class="tab-pane active" id="record_tab">
                    <div class="form-group row col-sm-12">
                        <label for="recordType" class="col-sm-3 col-form-label">Select Type:</label>
                        <div class="col-sm-9"><select class="form-control form-select-simplevalue" id="recordType" data-nodetype="type">
                            <option value="book">Book</option>
                            <option value="book-edited">Book (edited)</option>
                            <option value="contribution">Contribution in...</option>
                            <option value="journal-article">Journal Article</option>
                            <option value="newspaper-article">Newspaper Article</option>
                            <option>Other</option>
                        </select></div>
                    </div>
                
                <hr/>
                <div class="form-group row col-sm-12" data-showon="contribution">
                    <label for="field-ineditedvol" class="col-sm-3 col-form-label">In Book (edited):</label>
                    <div class="col-sm-9">
                        <input type="text" class="form-control-plaintext form-input form-simpletext" id="field-ineditedvol" data-nodetype="title"/>
                    </div>
                </div>    
                <div class="form-group row col-sm-12" data-showon="book book-edited contribution journal-article newspaper-article">
                    <label for="field-title" class="col-sm-3 col-form-label">Title:</label>
                    <div class="col-sm-9">
                        <input type="text" class="form-control-plaintext form-input form-simpletext" id="field-title" data-nodetype="title"/>
                    </div>
                </div>    
                <div class="form-group row col-sm-12" data-showon="book contribution journal-article">
                    <label for="field-author" class="col-sm-3 col-form-label">Author(s):</label>
                    <div class="col-sm-9">
                        <input type="text" class="form-control-plaintext form-input" id="field-author"/>
                    </div>
                </div>
                <div class="form-group row col-sm-12" data-showon="book book-edited">
                    <label for="field-editor" class="col-sm-3 col-form-label">Editor(s):</label>
                    <div class="col-sm-9">
                        <input type="text" class="form-control-plaintext form-input" id="field-editor"/>
                    </div>
                </div>
                <!--
                <div class="form-group row col-sm-12">
                    <label for="field-translator" class="col-sm-3 col-form-label">Translator(s):</label>
                    <div class="col-sm-9">
                        <input type="text" class="form-control-plaintext form-input" id="field-translator"/>
                    </div>
                </div>-->
                <div class="form-group row col-sm-12" data-showon="book book-edited journal-article newspaper-article">
                    <label for="field-year" class="col-sm-3 col-form-label">Year:</label>
                    <div class="col-sm-9">
                        <input type="text" class="form-control-plaintext form-input form-year form-simpletext" id="field-year" data-nodetype="date"/>
                    </div>
                </div>
                <hr/>
                <div class="form-group row col-sm-12" data-showon="book book-edited">
                    <label for="field-publisher" class="col-sm-3 col-form-label">Publisher:</label>
                    <div class="col-sm-9">
                        <input type="text" class="form-control-plaintext form-input " id="field-publisher"/>
                    </div>
                </div>
                <div class="form-group row col-sm-12" data-showon="book book-edited">
                    <label for="field-edition" class="col-sm-3 col-form-label">Edition:</label>
                    <div class="col-sm-9">
                        <input type="text" class="form-control-plaintext form-input form-simpletext" id="field-edition" data-nodetype="edition"/>
                    </div>
                </div>
                <div class="form-group row col-sm-12" data-showon="book book-edited">
                    <label for="field-description" class="col-sm-3 col-form-label">Description:</label>
                    <input type="text" class="form-control-plaintext form-input form-shortfield form-simpletext" data-nodetype="frontmatter"/> (frontmatter), 
                    <input type="text" class="form-control-plaintext form-input form-shortfield form-simpletext" data-nodetype="pagecount"/> pages; 
                    <input type="text" class="form-control-plaintext form-input form-shortfield form-simpletext" data-nodetype="dimension"/> cm 
                </div>
                <hr/>
                <div class="form-group row col-sm-12">
                    <label for="field-discover-0" class="col-sm-3 col-form-label">Discovered By:</label>
                    <div class="col-sm-8">
                        <input type="text" class="form-control-plaintext form-input" id="field-discover-0" placeholder="Name of Scholar"/>
                    </div>
                    <div class="col-sm-1">
                        <p type="text" class="form-control-plaintext"><button class="btn btn-mw-std btn-sm float-right"><i class="far fa-plus-square"/></button>
                        </p>
                    </div>
                </div>
                
               
                    <div class="form-group row col-sm-12">
                        <div class="col-sm-3"/>
                        <label for="comment" class="col-sm-2 col-form-label">Comment:</label>
                        <div class="col-sm-6">
                            <textarea class="form-input" rows="3" id="comment" placeholder="e.g. information about a publication"></textarea>
                        </div>
                    </div> 
                
                    
            </div>
            
            
            
            
            <div class="tab-pane" id="metadata_tab">
                <p>will come soon</p>
            </div>
            
            
            
            
            <div class="tab-pane" id="transcript_tab">
                <p>will come soon</p>
            </div>
            
            
            
            
            
            <div class="tab-pane" id="facsimile_tab">
                <p>will come soon</p>
            </div>
            
        </div></form>

};


declare 
    %templates:wrap
function app:print-title($node as node(), $model as map(*)) {
    for $x at $pos in $model("shelf")("soup")
        (:let $x:=$y//module[@n="1"]:)
        (:let $randomBookColor := "rgb("||47+util:random(63)||",37,37)":)
        let $randomBookColor := "rgb(96, 128, 0)"
        let $randomTextColor := "rgb(255,255,"||230+util:random(26)||")"
        let $maxTitleLength := 60
        let $fullTitle := string-join($x//title[1]//text())
        let $shortTitle := if (string-length($fullTitle)<$maxTitleLength) then $fullTitle else (substring($fullTitle,0,$maxTitleLength)||" (...)")
        
        let $authorIds := for $id in tokenize(functx:trim($x/author/@ref)," ")
                            return replace($id, '#', '')
        let $author := for $attr at $pos in $authorIds
                    return concat(
                            $x/ancestor::library//author[@xml:id = $attr]/lastname/text(),
                            if($x/ancestor::library//author[@xml:id = $attr]/firstname/text()) then (concat(", ",$x/ancestor::library//author[@xml:id = $attr]/firstname/text())) else "")

        let $background := if ($x//Cover) then "background: url(../data/modules/library-369088f9/thumbs/" || $x/Cover ||  ") no-repeat; background-size: 100% 100%; " else ""
        
        let $itemType := if ($x//type/text()="book") then "book" else "article"
        
        
        return
        <div class="libraryItem libraryItem-{$itemType} shelfCol-{$pos} app:print-title"  data-bookid="{data($x/@xml:id)}" style="{$background} background-color:{$randomBookColor}; color:{$randomTextColor};">
            { if ($x//Cover/@titleLegible="true") then "" else
            <div class="author">{$author[1]}{if(count($author) > 1) then " et al." else ""}</div>            
            }
            { if ($x//Cover/@titleLegible="true") then "" else
            <div class="title">{ $shortTitle }</div>}
            
        </div>
        (:<item position="{$pos}" value="{string($x)}"/>
    $model("shelf")("soup")//module[@n="1"][2]//Title[1]//text():)
};


declare %templates:wrap
function app:loadBibBook($node as node(), $model as map(*), $bookid as xs:string?) {
    (:TODO: get correct file by libraryid:)
    let $myBook := doc("../data/modules/library-30875cef/config.xml")//id($bookid)
    return map { "book" : $myBook}  

};

(:
declare %templates:wrap function app:bookTitle($node as node(), $model as map(*)){
    $model("book")//Title[1]/text()
};:)



declare %templates:wrap function app:bookMLAref($node as node(), $model as map(*)){

let $mybook := $model("book")

let $authorTxt := for $attr at $pos in tokenize($mybook/author/@ref, " ")
    let $separator := if ($pos > 1) then "; " else ""
    return concat($separator, $mybook/ancestor::library//author[concat("#",@xml:id)= $attr]/lastname/text(), ", ", $mybook/ancestor::library//author[concat("#",@xml:id)= $attr]/firstname/text())

return
    <span>
        <span class="author">{$authorTxt}</span>. 
        <span class="title mlaTitle">{$mybook//title[1]/text()}</span>. 
        <span class="place">{$model("book")//Place[1]/text()}</span>: 
        <span class="publisher">{$model("book")//Publisher[1]/text()}</span>, 
        <span class="year">{$mybook//date[1]/text()}</span>.
    </span>
};



declare %templates:wrap function app:bookPages($node as node(), $model as map(*)){
    <span/>
};

declare %templates:wrap function app:bookCountRecords($node as node(), $model as map(*)){
    <span>We recorded {count($model("book")//zone)} reading traces on {count($model("book")//page)} different pages.</span>
};

declare %templates:wrap function app:bookGoesToList($node as node(), $model as map(*)){
    for $x in $model("book")//docList/doc
        return <span>{if($x/@cert="probably")then "potential source for " else""}<a href="#">{$x/text()}</a> (Notebook)</span>
};


declare %templates:wrap function  app:traceChangeButton($node as node(), $model as map(*)){
     let $records := count($model("book")//zone)
     return if ($records=0) then "" else
                    <div class="input-group input-group-sm app:traceChangeButton">
                        <div class="input-group-prepend"> 
                            <a class="btn btn-outline-secondary carousel-control-prev" href="#carouselExampleIndicators" role="button" data-slide="prev" onclick="traceCounter(-1)">&lt;</a>
                        </div>
                        <input class="happyInput" aria-label="Text input with checkbox" placeholder="1" type="text"/>
                        <div class="input-group-append"><span class="input-group-text">/{$records}</span>
                            <a class="btn btn-outline-secondary carousel-control-next" href="#carouselExampleIndicators" role="button" data-slide="next" onclick="traceCounter(1)">&gt;</a></div>
                    </div>
};

declare %templates:wrap function app:sourceCertainty($node as node(), $model as map(*)){
   $model("book")//Certainty[1]/text()

};



declare %templates:wrap function  app:readingTraceSlider($node as node(), $model as map(*)){
     let $records := count($model("book")//zone)
     return if ($records=0) then "no records for this book" else 
        <div id="carouselExampleIndicators" class="carousel slide" data-ride="carousel" data-interval="false">
                    <div class="carousel-inner">
                        <div class="carousel-item active">
                            <div class="row">
                                <div class="card col-sm-6 col-md-6 ">
                                    <div class="card-body">Sullivan 1920: 1</div>
                                    <img class="card-img-top" src="../data/modules/library-369088f9/fakePages/k-a.JPG" alt="Card image"/>
                                </div>
                                <div class="card card col-sm-6 col-md-6">
                                    <div class="card-body">VI.B.6 p.056 note (a)</div>
                                    <img class="card-img-top" src="../data/modules/library-369088f9/fakePages/a.JPG" alt="Card image"/>
                                </div>
                            </div>
                            
                        </div>
                        <div class="carousel-item">
                            <div class="row">
                                <div class="card col-sm-6 col-md-6 ">
                                    <div class="card-body">Sullivan 1920: 1</div>
                                    <img class="card-img-top" src="../data/modules/library-369088f9/fakePages/k-b.JPG" alt="Card image"/>
                                </div>
                                <div class="card card col-sm-6 col-md-6">
                                    <div class="card-body">VI.B.6 p.056 note (b)</div>
                                    <img class="card-img-top" src="../data/modules/library-369088f9/fakePages/b.JPG" alt="Card image"/>
                                </div>
                            </div>
                        </div>
                        <div class="carousel-item">
                            <div class="row">
                                <div class="card col-sm-6 col-md-6 ">
                                    <div class="card-body">Sullivan 1920: 2</div>
                                    <img class="card-img-top" src="../data/modules/library-369088f9/fakePages/k-c.JPG" alt="Card image"/>
                                </div>
                                <div class="card card col-sm-6 col-md-6">
                                    <div class="card-body">VI.B.6 p.056 note (c)</div>
                                    <img class="card-img-top" src="../data/modules/library-369088f9/fakePages/c.JPG" alt="Card image"/>
                                </div>
                            </div>
                        </div>
                    </div>
             </div>   
};



declare function app:newDocCloseButton($node as node(), $model as map(*), $entrypoint as xs:string?){
    <button class="btn btn-mw-outline my-2 save-newDoc" data-entrypoint="{$entrypoint}">
                        <i class="far fa-save"/> Close
    </button>
};


declare function app:getBreadCrumbs($node as node(), $model as map(*), $resource as xs:string?){
            let $idPath := mw:getCollectionPathById($resource)
            let $tokenizedPath := fn:tokenize(functx:trim($idPath), '/')
            return 
                <div class="breadcrumbs">
                <ol class="breadcrumb">
                    <li class="breadcrumb-toggle" aria-current="page"><i class="fas fa-times-circle" style="margin-right: 15px;"></i></li>
                    <li class="breadcrumb-item" aria-current="page">
                            <span class="explorer-link" data-shownurl="/Home/">Home</span>
                    </li>
                    <li class="breadcrumb-item {if ($resource) then () else "active"}" aria-current="page">
                            <span class="explorer-link" data-shownurl="/Modules/">Modules</span>
                    </li>
                    
                    {
                            for $segId at $p in $tokenizedPath 
                                return if(functx:all-whitespace(mw:getURLlabel(functx:trim($segId)))) then () 
                                else (
                                    (:libraries are directed to another template than all other modules:)
                                    let $modOrLib := if (mw:getModuleType($resource) = "library" ) then "library" else "module"
                                    return 
                                    <li class="breadcrumb-item {if ($segId = $resource) then "active" else ""}" aria-current="page">
                                        <span class="explorer-link" data-explorerurl="/exist/apps/ManuscriptWeb/templates/{$modOrLib}-content.html?resource={$segId}" data-shownurl="{mw:getRelativeURLpath($segId)}" >{mw:getResourceLabel($segId)}</span>
                                    </li>
                                )
                     }
                     

                 </ol></div>

};


declare 
    %templates:wrap  
function  app:iv-loaddoc($node as node(), $model as map(*), $resource as xs:string?, $imgnum as xs:string?) as map(*) {
    let $imgPath := mw:getCollectionPathById($resource)
    let $imageInfo := doc($imgPath|| '/mapping.xml' )//imageSequence/image
    (:todo: add whatever else should go into the map here.... :)
    return 
        map{ "images" : $imageInfo,
             "imagePath" : replace($imgPath, '/db/apps', '/exist/apps'),
             "imgNum" : $imgnum
        }
};

declare 
    %templates:wrap 
function app:iv-printImages($node as node(), $model as map(*)){
    let $imgNum := if ($model("imgNum")) then $model("imgNum") else 1
    for $im at $pos in $model("images")
    return
    <a class="iv-thumb-link {if (string($pos) = string($imgNum) ) then 'active' else "" }" data-resourceid="{data($im/@xml:id)}" data-imgnum="{$pos}">
        <img class="iv-thumb-img" src="{$model("imagePath") ||"/facsimiles/thumbs/"|| data($im/@ref)}"/>
    </a>
};


declare function app:tv-transcriptselector($node as node(), $model as map(*),$resource as xs:string?, $tsnum as xs:int?){
    
    let $collectionPath := mw:getCollectionPathById($resource)
    let $configuration := doc($collectionPath ||'/mapping.xml' )//transcriptSequence/transcript
    let $tsnum := if ($tsnum and $tsnum > count($configuration)) then $tsnum else 1
    return
        <div class="tv-transSelector" style="display:inline-block">
            <select class="transcriptSelect">
                { for $thing at $pos in $configuration 
                
                  return if ($pos= $tsnum) then
                            <option value="{data($thing/@ref)}" data-file="{data($thing/@xml:id)}" selected="">{data($thing/@ref)}</option> 
                  else
                            <option value="{data($thing/@ref)}" data-file="{data($thing/@xml:id)}">{data($thing/@ref)}</option>
                }
            </select>
        </div>
};

declare function app:textpreview($node as node(), $model as map(*), $resource as xs:string?){
    let $collectionPath := mw:getCollectionPathById($resource)
    let $configuration := doc($collectionPath ||'/mapping.xml' )//transcriptSequence/transcript
    return
        <div class="transcriptArea">
            {viewstuff:loadingSpinner("Transcript")}
            
            <!--
                todo: call javscript function loadTEI($whatever) here?
                then everything that leads to the production of $file can actually go! 
                
            <xml>
                
                {$file}
            </xml>-->
        </div>
};


(:function loads the correct template page from the GeneralSettings file depending on the passed URL parameter embeddedPage:)
declare function app:loadtemplate($node as node(), $model as map(*), $servetemplate as xs:string?){
    let $link := doc($config:app-root||"/config/GeneralSettings.xml")//Section[@name="pages"]/Page[@url = $servetemplate][1]/data(@serve)
    return 
        try {
            (:process templates on the doc!:)
            templates:process(doc($config:app-root||"/"||$link),$model)} 
        catch err:notFound{
            "page not available"
        }
};

(:collects the Google fonts from the GeneralSettings file to provide the link for page.html:)
declare function app:getGoogleFonts($node as node(), $model as map(*)){
    let $fontNames := for $font in doc($config:app-root||"/config/GeneralSettings.xml")//CSSvar[@type="googlefont"]/text() return replace($font," ","+")
    return
    <link rel="stylesheet" type="text/css" href="//fonts.googleapis.com/css?family={string-join($fontNames,"|")}"/>
};


declare function app:test($node as node(), $model as map(*), $testvar as xs:string?){
<p>this is just a test paragraph to see if this function is called. a further test is $testvar. it was set to the value: {$testvar}</p>
};


(:this inserts the value into css-var input fields:)
declare function app:getCssVarTemplate($node as node(), $model as map(*), $cssvar as xs:string?){
    let $setting := doc($config:app-root||"/config/GeneralSettings.xml")//id($cssvar)
    return if ($setting/data(@type)="color") then
    <input type="color" class="css-var" data-cssvar="{$cssvar}" value="{$setting/text()}"/>
    else if ($setting/data(@type)="googlefont") then
    <select id="select_{$cssvar}" class="fontselector" data-cssvar="{$cssvar}" value="{$setting/text()}" style="width: 230px;"/>
    else ""
};
