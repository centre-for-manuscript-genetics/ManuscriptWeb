xquery version "3.1";


import module namespace config = "http://exist-db.org/apps/ManuscriptWeb/config" at "../config.xqm";
import module namespace mw = "http://exist-db.org/apps/ManuscriptWeb/mw" at "../mw.xql";
import module namespace viewstuff = "http://exist-db.org/apps/ManuscriptWeb/fun" at "../view-functions.xql";
import module namespace functx = "http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:edit this one :)
let $datesource := doc(concat($config:data-root,"/BSeriesDates.xml"))

let $collection := collection(concat($config:data-root, "/modules/notes-buffalo/collection-60d99c14/"))

let $elements := $collection//tei:title

return
    <els>{
        for $element in $elements
            let $root := root($element)
            
            let $filename := substring-before(util:document-name($element), ".xml")
            let $relevantDates := $datesource//row[./Name/text() = $filename]
            
            let $titleStmt := <titleStmt>
                                    <title>{$filename}</title>
                                    <author>James Joyce</author>
                                    <editor>Danis Rose</editor>
                                    <editor>John O'Hanlon</editor>
                                    
                                    <respStmt>
                                        <name>Danis Rose</name>
                                        <resp>Editor</resp>
                                        <resp>Transcription</resp>
                                        <resp>Critical Assessment</resp>
                                    </respStmt>
                                    <respStmt>
                                        <name>John O'Hanlon</name>
                                        <resp>Editor</resp>
                                        <resp>Transcription</resp>
                                        <resp>Critical Assessment</resp>
                                    </respStmt>
                                    <respStmt>
                                        <name>Joshua Schäuble</name>
                                        <resp>TEI Version</resp>
                                        <resp>Data Modelling, Transformation and Correction</resp>
                                    </respStmt>
                                </titleStmt>
                                
              let $replaceTitleStmt := update replace $root//tei:titleStmt with $titleStmt
              let $profileDesc :=   <profileDesc>
                            				<creation>
                            					<date type="mw-chronology" notBefore="{$relevantDates/FromDate/text()}" notAfter="{$relevantDates/ToDate/text()}"/>
                            				</creation>
                            		</profileDesc>	
              let $insertProfile := update insert $profileDesc into $root//tei:teiHeader
            
            return
                <a>{util:document-name($element)}: {$filename} : {$relevantDates/Name/text()}</a>
        }
    </els>