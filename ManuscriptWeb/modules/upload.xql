xquery version "3.1";

import module namespace config="http://exist-db.org/apps/ManuscriptWeb/config" at "config.xqm";
import module namespace mw ="http://exist-db.org/apps/ManuscriptWeb/mw" at "mw.xql";
import module namespace functx = "http://www.functx.com" at "/db/system/repo/functx-1.0/functx/functx.xql";
import module namespace admin = "http://exist-db.org/apps/ManuscriptWeb/admin" at "admin.xql";

declare namespace json="http://www.json.org";


declare option exist:serialize "method=json media-type=application/json";

declare function local:upload($root, $paths, $payloads) {
    let $collectionFolder := mw:getCollectionPathById($root)
    let $paths :=
        for-each-pair($paths, $payloads, function($path, $data) {
                (:todo: mime type would be better than file-ending:)
                let $fileExt := functx:substring-after-last($path,".")
                (:decide which subfolder to put the file in based on its extension:)
                let $subfolder := 
                        if ($fileExt=('txt','html','xml')) then 'transcripts' 
                        else if ($fileExt=("jpg","jpeg","png","JPG","JPEG","PNG")) then "facsimiles" 
                        else "none"
                let $storeFile := 
                                    if ($subfolder="facsimiles") then local:addImage($collectionFolder, $subfolder, $path, $data)
                                        else if ($subfolder="transcripts") then local:addTranscript($collectionFolder, $subfolder, $path, $data)
                                            else ""
                return map {'fullpath': $storeFile, 'filefolder': $subfolder}
        })
    return
        map {
            "files": array {
                for $path in $paths
                return
                    map {
                        "name": functx:substring-after-last($path("fullpath"),'/'),
                        "path": substring-after($path("fullpath"), $config:data-root || "/"),
                        "type": xmldb:get-mime-type($path("fullpath")),
                        "size": 93928,
                        "fullURL": $path("fullpath"),
                        "foldertype" : $path("filefolder"),
                        "collectionPath" : $collectionFolder
                    }
            }
        }
};


declare function local:addTranscript($collectionFolder as xs:string, $subfolder as xs:string, $path as xs:string, $data as item()){
    let $fullFolder := concat($collectionFolder,"/",$subfolder)
    
    let $saveTranscript := xmldb:store($fullFolder, $path,  $data)
    
    (:take transcript sequence from config-file:)
    let $conf := doc(concat($collectionFolder,'/mapping.xml'))
    let $config := $conf//transcriptSequence[1]
    let $newId := admin:createUniqueID("transcript")
    let $label := admin:unifyLabel($conf,functx:substring-before-last( tokenize($path, '/')[last()], '.'),$newId)
    
    (: add image entry to config file:)
    let $xmlSequence := 
                        <transcript xml:id='{$newId}' ref='{$path}'>
                            <label>{$label}</label>
                            <urllabel>{admin:createURLIdentifier($label)}</urllabel>
                        </transcript>
    let $enterTranscript := update insert $xmlSequence into $config
    
    
    return $saveTranscript    
};


declare function local:addImage($collectionFolder as xs:string, $subfolder as xs:string, $path as xs:string, $data as item()) {
    (:store image in 3 sizes: original size in facsimile folder, medium size in medium folder and thumbnail size in thumbs folder:)
    let $fullFolder := concat($collectionFolder,"/",$subfolder)
    
    let $regularSize := xmldb:store($fullFolder, $path,  $data)
    let $mediumSize := xmldb:store($fullFolder||"/medium/", $path, image:scale($data,(1200,1200), xmldb:get-mime-type($regularSize)))
    let $thumbSize := xmldb:store($fullFolder||"/thumbs/", $path, image:scale($data,(100,100), xmldb:get-mime-type($regularSize)))
    
    
    (:take image sequence from config-file:)
    let $conf := doc(concat($collectionFolder,'/mapping.xml'))
    let $config := $conf//imageSequence[1]
    let $newId := admin:createUniqueID("image")
    let $label := admin:unifyLabel($conf,functx:substring-before-last( tokenize($path, '/')[last()], '.'),$newId)
    
    (: add image entry to config file:)
    let $xmlSequence := 
                        <image xml:id='{$newId}' ref='{$path}'>
                            <label>{$label}</label>
                            <urllabel>{admin:createURLIdentifier($label)}</urllabel>
                        </image>
    let $enterPic := update insert $xmlSequence into $config
    
    
    return $regularSize    
    
};

let $name := request:get-uploaded-file-name("files[]")
let $data := request:get-uploaded-file-data("files[]")
let $root := request:get-parameter("root", "")
return
    try {
        local:upload($root, $name, $data)
    } catch * {
        map {
            "name": $name,
            "error": $err:description
        }
    }
