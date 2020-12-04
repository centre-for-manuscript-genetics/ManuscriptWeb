xquery version "3.1";


import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "../config.xqm";
import module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw" at "../mw.xql";
import module namespace admin = "http://exist-db.org/apps/ManuscriptWeb/admin" at "../admin.xql";
import module namespace viewstuff = "http://exist-db.org/apps/ManuscriptWeb/fun" at "../view-functions.xql";
import module namespace functx = "http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $nodes := doc($config:data-root || "/libraryAuthors/authorCollection.xml")//author


return <hits>{
for $rel in $nodes
    let $id := $rel/AuthorID/text()
    let $update := update insert attribute xml:id{$id} into $rel
    return <a>{$rel/@xml:id}</a>
}
</hits>