xquery version "3.1";


import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "../config.xqm";
import module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw" at "../mw.xql";
import module namespace viewstuff = "http://exist-db.org/apps/ManuscriptWeb/fun" at "../view-functions.xql";
import module namespace functx = "http://www.functx.com";
import module namespace admin = "http://exist-db.org/apps/ManuscriptWeb/admin" at "../admin.xql";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $nodes := doc(concat($config:data-root, "/relations/sourceToNbRelations.xml"))//relation

return <hit>
{
    for $relation in $nodes
        let $lookup := collection(concat($config:data-root, "/modules"))//id($relation/to/@phraseId)
       (: let $fromDate := update insert attribute notBefore {$lookup/preceding::tei:date[@type = "mw-chronology"]/data(@notBefore)} into $relation/date
        let $toDate := update insert attribute notAfter {$lookup/preceding::tei:date[@type = "mw-chronology"]/data(@notAfter)} into $relation/date:)
        return <note>{$relation/data(@xml:id)}:: done</note>

}

</hit>