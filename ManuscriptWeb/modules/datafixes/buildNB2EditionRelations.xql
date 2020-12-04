xquery version "3.1";


import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "../config.xqm";
import module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw" at "../mw.xql";
import module namespace viewstuff = "http://exist-db.org/apps/ManuscriptWeb/fun" at "../view-functions.xql";
import module namespace functx = "http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $nodes := collection(concat($config:data-root, "/quickScrape"))//item[.//ul//text()[contains(.,"FW")]]

(:let $toDoc := doc(concat($config:data-root, "/modules/editions-358f34d0/edition-b55f9083/transcripts/finnegans-wake.xml"))//tei:l/data(@xml:id):)


return <relations> {
    for $node in $nodes 
            let $fromPhraseId := $node/data(@xml:id)
            
            let $refString := for $el in $node//ul//text()[contains(.,"FW")] return   functx:trim(substring-after($el,"FW"))   
            
            
            let $doc := collection(concat($config:data-root, "/modules/notes-buffalo/collection-60d99c14"))//id($fromPhraseId)
            let $FromDocId := document-uri( root($doc))
            
           (:
           ALTERNATIVE PHRASEID
                {
                    for $id in $refString return if (not($id="") and contains($id,".")) then 
                            let $countF := count(tokenize($id,"f"))-1
                            let $countH := count(tokenize($id,"\-"))-1
                            let $noF := functx:substring-before-if-contains(replace($id,"f",""),"-")
                            let $res := $toDoc[contains(.,concat(".",$noF))]
                            return
                                if( $countF >1 or $countH >1 or count($res) > 1) then () else
                                                                for $re in $res return $re
                            else ()
                
                }
           
           :)
           
            
            return if (count($refString)>1 or contains($refString,"unlocated") or contains($refString,"isotext")) 
            then 
                <relation uncertain="true">
                    <from phraseId="{$fromPhraseId}" docId="{tokenize($FromDocId,"/")[9]}" />
                    <to phraseId="{for $el in $refString return concat($el," ") }" docId="edition-b55f9083"/>
                </relation>
            else
                
                <relation>
                    <from phraseId="{$fromPhraseId}" docId="{tokenize($FromDocId,"/")[9]}" />
                    <to phraseId="{$refString}" docId="edition-b55f9083"/>
                </relation>


}






</relations>