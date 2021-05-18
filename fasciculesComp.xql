xquery version "3.1";
(:~ 
 : XQuery  module to extract a correspondence of texts and units
 : from  data encoded according to the Beta Masaheft Guidelines and TEI Schema.
 : @author Pietro Maria Liuzzo
 : @version 1.0
 :)
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace s = "http://www.w3.org/2005/xpath-functions";

let $ms := doc('../../BetMes/Manuscripts/Ham/DabraLibanosHamGG1/DabraLibanosHamGG1.xml') 
return
<html><head><title>Comparison of the contents in the small quire with the content of the leaves of the same size as the mss.</title></head><body>
<table>
<thead>
<tr>
<th>textid</th>
<th>leaves of the same size of the mss</th> 
<th>small Quire</th>
</tr></thead>
<tbody>{for $msItem in $ms//t:msPart[@xml:id='p2']//t:msContents/t:msItem
let $id := $msItem/@xml:id
let $locus := $msItem/t:locus
let $placement := string($locus/@from) ||'-'|| string($locus/@to)
let $title := $msItem/t:title
let $ref := $title/@ref
let $hand := $ms//t:handNote[substring-after(@corresp, '#') = $id]
let $handdesc := normalize-space(string-join($hand//text()))
let $matchingentry := $ms//t:title[not(ancestor::t:msPart[@xml:id='p2'])][@ref = $ref]
return
<tr>
<td>{string($ref)}</td>
<td>{for $m in $matchingentry 
let $type := if ($m/parent::t:msItem) then 'main' else 'addition'
let $matchingentryId :=if ($m/parent::t:msItem) then $m/parent::t:msItem/@xml:id else $m/ancestor::t:item/@xml:id
let $matchinghand := $ms//t:handNote[substring-after(@corresp, '#') = $matchingentryId]
let $matchinghanddesc := normalize-space(string-join($matchinghand//text()))
let $matchinglocus := if ($m/parent::t:msItem) then $m/parent::t:msItem/t:locus[1] else $m/ancestor::t:item/t:locus[1]
let $matchinplacement := string($matchinglocus[1]/@from) ||'-'|| string($matchinglocus[1]/@to)
 return
 ($matchinplacement, $type, $matchinghanddesc)}</td>
<td>{$placement, 'main',  $handdesc}</td>
</tr>
}
</tbody>
</table>
</body></html>

