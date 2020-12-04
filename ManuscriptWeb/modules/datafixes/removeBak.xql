import module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw" at "../mw.xql";
import module namespace viewstuff = "http://exist-db.org/apps/ManuscriptWeb/fun" at "../view-functions.xql";
import module namespace functx = "http://www.functx.com";
import module namespace admin = "http://exist-db.org/apps/ManuscriptWeb/admin" at "../admin.xql";
import module namespace config="http://exist-db.org/apps/ManuscriptWeb/config" at "config.xqm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


let $collection := collection(concat($config:data-root, "/modules"))//tei:TEI

return <res>
{for $file in $collection
    let $resource := substring-after(base-uri($file), 'transcripts/')
    let $uri := substring-before(base-uri($file), '/VI')
    (:let $remove := xmldb:remove(base-uri($file),$uri)
     let $remove := xmldb:remove(xs:anyURI(concat($config:data-root,"/modules/notes-buffalo/collection-60d99c14/notebook-d8e55df9/transcripts")),"VI.B.24.xml.bak"):)
    return if (contains(base-uri($file),".bak")) then <A>{$resource} :::  {$uri}</A> else ()
    }
</res>