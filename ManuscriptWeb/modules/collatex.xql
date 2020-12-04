
xquery version "3.1";

import module namespace http="http://expath.org/ns/http-client";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace functx="http://www.functx.com";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "config.xqm";


let $a := "die katze tritt die Treppe krumm"
let $b := "der kater tritt die Truppe krumm."

(:let $file-url := "0.0.0.0:7369/collate"
let $request := <hc:request href="{$file-url}" method="GET"/>


let $response := hc:send-request($request)
let $type := response:set-header("Content-Type","application/json")
let $accept := response:set-header("Accept","application/tei+xml"):)
let $a:= '{
  "witnesses" : [
    {
      "id" : "A",
      "content" : "A black cat in a black basket"
    },
    {
      "id" : "B",
      "content" : "A black cat in a red basket"
    }]}'

let $request := http:send-request(
   <http:request href="http://0.0.0.0:7369/collate" method="post">
      <http:header name="Accept" value="application/tei+xml"/>
      <http:body media-type="application/json">
       {util:base64-encode($a)}
      </http:body>
   </http:request>
)
(:to use with binary responses::)
(:return util:base64-decode($request[2]):)

return $request[2]