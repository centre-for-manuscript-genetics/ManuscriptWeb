xquery version "3.1";


import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "../config.xqm";
import module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw" at "../mw.xql";
import module namespace viewstuff = "http://exist-db.org/apps/ManuscriptWeb/fun" at "../view-functions.xql";
import module namespace functx = "http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


(:edit this one :)
let $datesource := doc(concat($config:data-root,"/modules/notes-buffalo/collection-bseries/notebook-vib10/transcripts/VI.B.10.xml"))//tei:div[@type="page"]

return
    <sourceDoc>{
        for $element in $datesource
             let $id := $element/@xml:id
             let $id_clean := replace($id, "\." , "_")
             return
            <surface xml:id="surface_{$id_clean}"  type="iiif-canvas" facs="http://localhost/iipsrv/iipsrv.fcgi?IIIF=B10wm/{$id}.tif/info.json" >
    			<graphic xml:id="graphic_{$id_clean}" url="http://localhost/iipsrv/iipsrv.fcgi?IIIF=B10wm/{$id}.tif/info.json"/>
    		</surface>
        }
    </sourceDoc>
        
        
        
		