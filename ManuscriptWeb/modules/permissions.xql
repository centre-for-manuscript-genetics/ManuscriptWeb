xquery version "3.0";

import module namespace dbutil="http://exist-db.org/xquery/dbutil";

dbutil:scan(xs:anyURI("/db/apps/ManuscriptWeb/data"), function($collection, $resource) {
    if ($resource) then (
        sm:chown($resource, "joshua:ManuscriptWeb")
    ) else if ($collection) then
        sm:chown($collection, "joshua:ManuscriptWeb")
      else  ()
})