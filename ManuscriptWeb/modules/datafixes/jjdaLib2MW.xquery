xquery version "3.1";

import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "../config.xqm";
import module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw" at "../mw.xql";
import module namespace viewstuff = "http://exist-db.org/apps/ManuscriptWeb/fun" at "../view-functions.xql";
import module namespace functx = "http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "text";

:)

(:edit this one :)
let $datasource := doc(concat($config:data-root,"/sources.xml"))//dl

return 

<sources>
    {for $element in $datasource
       let $dateString := $element/span/stitle/following-sibling::text()[contains(.,"(")]
       let $date := substring-before(substring-after(string-join($dateString),":"),")")
       let $place := substring-after(substring-before(string-join($dateString),":"),"(")
       return 
       <item xml:id="" jjdaId="{$element/data(@id)}">
            <title>{for $el in $element//stitle return data($el)} 
            {if ($element//stitle/following-sibling::*[1 and name() = "cite"]) then " in: " else ()}
                   {for $el in $element//stitle/following-sibling::*[1 and name() = "cite"] return <title>{data($el)}</title>}
            </title>
            <type>{ 
                if (   string-length(      replace($element/data(@id), '[^\d]', '') )        > 1) 
                then "newspaper" 
                else if ($element//stitle/following-sibling::*[1 and name() = "cite"]) then "contribution"
                else "book"}</type>
            <date>{$date}</date>
            <author>{for $el in $element//sauthor return data($el)}</author>
            <publisher>{$dateString}</publisher>
            <place>{$place}</place>
            <credits>{$element//li[contains(data(), "Identified")]/replace(data(),"Identified by:","")}</credits>
            <bib></bib>
            <num></num>
            <allOrigCit>{$element/span/data()}</allOrigCit>
       </item>
    }
</sources>