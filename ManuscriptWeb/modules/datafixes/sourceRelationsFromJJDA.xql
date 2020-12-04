xquery version "3.1";


import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "../config.xqm";
import module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw" at "../mw.xql";
import module namespace viewstuff = "http://exist-db.org/apps/ManuscriptWeb/fun" at "../view-functions.xql";
import module namespace functx = "http://www.functx.com";
import module namespace admin = "http://exist-db.org/apps/ManuscriptWeb/admin" at "../admin.xql";

let $nodes := collection(concat($config:data-root, "/quickScrape"))//footer

return
    <relations>{
            for $node in $nodes
            
            let $nodeId := $node/ancestor::item/data(@xml:id)
            let $citation := $node/ancestor::blockquote/p
            let $range := $node/text()[last()]
            let $sourceId := $node/a/data(@name)
            
            let $doc := collection(concat($config:data-root, "/modules/notes-buffalo/collection-60d99c14"))//id($nodeId)
            let $toDocId := document-uri( root($doc))
            return
            
                <relation xml:id="{admin:createUniqueID("relation")}">
                    <from phraseId="" docId="" jjdaSourceId="{$node//a/data(@name)}"/>
                    <to phraseId="{$nodeId}" docId="{tokenize($toDocId,"/")[9]}"/>
                    <date type="mw:chronology"/>
                    
                    
                    <!--just some extra info--> 
                    <citationInfo>{$range}</citationInfo>
                    <quote>{$citation}</quote>
                </relation>
        }
    </relations>