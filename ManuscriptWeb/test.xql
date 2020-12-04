xquery version "3.0";

import module namespace dbutil="http://exist-db.org/xquery/dbutil";

dbutil:scan(xs:anyURI("/db/apps/ManuscriptWeb/data"), function($collection, $resource) {
    if ($resource) then (
        sm:chown($resource, "joshua:ManuscriptWeb")
        sm:chmod($resource, "rwxrwxr-x") 
    ) else if ($collection) then
        sm:chown($collection, "joshua:ManuscriptWeb")
        sm:chmod($collection, "rwxrwxr-x") 
      else  ()
})