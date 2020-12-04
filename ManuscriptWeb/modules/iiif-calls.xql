declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";


declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace request="http://exist-db.org/xquery/request";

declare option output:method "json";
declare option output:media-type "application/json";



import module namespace iiif ="http://exist-db.org/apps/ManuscriptWeb/iiif" at "iiif.xql";



(: the GET parameter "action" decides, which XQuery function to call:)
let $get := request:get-parameter('get','')
let $resid:= request:get-parameter('resid','')
(:Call/return XQuery functions depending on the value of the 'action' parameter :)
return switch ($get)
       case "manifest"
            return iiif:getManifest($resid)
       case "sequence"
            return iiif:getSequences($resid)
       case "canvas"
            return iiif:getCanvas($resid)
       default return <p>the passed action cannot be processed.</p>