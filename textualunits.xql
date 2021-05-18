xquery version "3.1";
(:~ 
 : XQuery  module to extract a correspondence of texts and units
 : from  data encoded according to the Beta Masaheft Guidelines and TEI Schema.
 : @author Pietro Maria Liuzzo
 : @version 1.0
 :)
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace s = "http://www.w3.org/2005/xpath-functions";

(:new ref system placement, CCR Clavis ID, CCR number, title, main content or addition :)
let $ms := doc('../../BetMes/Manuscripts/Ham/DabraLibanosHamGG1/DabraLibanosHamGG1.xml') 
let $works := collection('file:///users/pietro/documents/BetMes/Works/new/?select=*.xml;recurse=yes')//t:TEI
return
('order, from, to, xml:id, CAe, BMid, CCR, title, type
',
for $title in $ms//t:title[parent::t:msItem or ancestor::t:item]
let $r := $title/@ref 
let $work:=$works[@xml:id=$r]
let $bibl := $work//t:div[@type='bibliography']//t:ptr[@target='bm:ContiRossini1901Evangelodoro']
let $CCR := if($bibl) then 'CCR ' || $bibl/following-sibling::t:citedRange[@unit='item']/text() else 'not in CCR'
let $reftit := if($title/@ref) then $work//t:title[@xml:id='t1']/text() else $title/text()
let $placement := if ($title/parent::t:msItem) then $title/preceding-sibling::t:locus else $title/ancestor::t:item/t:locus
let $id := if ($title/parent::t:msItem) then string($title/parent::t:msItem/@xml:id) else string($title/ancestor::t:item/@xml:id)
let $formatplace := string($placement/@from) || ', ' || string($placement/@to)
let $mainoradd := if ($title/parent::t:msItem) then 'main' else 'addition'
let $order := count($title/preceding::t:title)
order by $order
return 
($order || ','|| $formatplace ||','||$id||','|| 'CAe ' || substring($title/@ref, 4, 4) ||', ' 
|| string($title/@ref) ||','|| $CCR || ', ' || $reftit ||', ' ||$mainoradd||'
'))