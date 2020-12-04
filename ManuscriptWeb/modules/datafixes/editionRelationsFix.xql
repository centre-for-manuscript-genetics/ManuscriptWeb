xquery version "3.1";


import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "../config.xqm";
import module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw" at "../mw.xql";
import module namespace viewstuff = "http://exist-db.org/apps/ManuscriptWeb/fun" at "../view-functions.xql";
import module namespace functx = "http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $nodes := doc(concat($config:data-root, "/relations/editionRelations.xml"))//relation[not(@uncertain)]/to/data(@phraseId)
let $toDoc := doc(concat($config:data-root, "/modules/editions-358f34d0/edition-b55f9083/transcripts/finnegans-wake.xml"))//tei:l/data(@xml:id)


return <hu>{

(:for $el in $toDoc return <a>{$el}</a>:)
 for $id in $nodes 

    let $countF := count(tokenize($id,"f"))-1
    let $countH := count(tokenize($id,"\-"))-1
    let $noF := functx:substring-before-if-contains(replace($id,"f",""),"-")
   
    let $res := $toDoc[contains(.,concat(".",$noF))]
    
    return
            <a countF="{$countF}" countH="{$countH}"><els>{for $re in $res return <el xml:id="{$id}">{$re}</el>}</els> </a> 
        
     
}
</hu>