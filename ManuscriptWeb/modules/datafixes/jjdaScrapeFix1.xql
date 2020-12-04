xquery version "3.1";


import module namespace config="http://exist-db.org/apps/ManuscriptWeb/config" at "../config.xqm";
import module namespace mw ="http://exist-db.org/apps/ManuscriptWeb/mw" at "../mw.xql";
import module namespace viewstuff="http://exist-db.org/apps/ManuscriptWeb/fun" at "../view-functions.xql";
import module namespace functx="http://www.functx.com"; 
declare namespace tei = "http://www.tei-c.org/ns/1.0";


let $collection := doc(concat($config:data-root,"/modules/notes-buffalo/collection-60d99c14/notebook-b1/transcripts/VI.B.1.xml"))

(:let $elements := $collection//hi[@color]

return <hits>
{
for $el in $elements
   
   let $value := $el/data(@color)
   let $attr := update insert attribute style {$value} into $el
   let $delete := update delete $el/@color
   return <hit>{$el}</hit>
}
</hits>:)


let $elements := $collection//tei:div[@type="page"]


return <hits>
count: {count($elements)}
{
for $el in $elements
   (:let $val := concat("#graphic_VIB01_",xs:int(tokenize($el/data(@xml:id),"\.")[last()])):)
   let $myid := replace($el/data(@facs),"#","")
   let $myEl := $collection/id($myid)
    (:let $attr := update insert attribute facs {$val} into $el:)
  
   (:let $delete := update delete $el/@class:)
   return <hit>{$myEl}</hit>
}
</hits>


(:remove an element but keep its children:)
(:
let $elements := $collection//span[@class="strike"]


return <hits>
{
for $el in $elements
   return if ($el/*) then
                let $attr := update replace $el with $el/*
                return <hit>{$el}</hit> 
            else <hit>none</hit>
}
</hits>:)

