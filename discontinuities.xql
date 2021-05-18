xquery version "3.1";
(:~ 
 : XQuery  module to extract a table of units and identify convergent discontinuities 
 : according to La Syntaxe du Codex
 : from  data encoded according to the Beta Masaheft Guidelines and TEI Schema.
 : @see http://hdl.handle.net/2333.1/kh189d69
 : @author Pietro Maria Liuzzo https://orcid.org/0000-0001-5714-4011
 : @version 1.0
 :)
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
(:~ 
 :This function takes the value of an attribute @to or @from from a t:locus element and transforms it into a numeric value
 : which can be put in a continuous sequence.
 : It also takes into account if this is a end or start limit
 : the value of the folio number is concatenated with a 1 or a 2 for recto or verso, 1 or 2 for the column and a value normalized to
 : hundreds for line numbers
 : from=1 will be  00100000  where:
 : - 1 is the folio number formatted as 001, 
 : - the fourth position is the recto or verso
 : - the fifth position is the number of the colum
 : - the last three digits are the line, where 1 will be 010, 10 will be 100, 12 will be 120, etc.
 : to=2 will be instead 00299999 and the rest will be the same :)
declare function local:numericLocusformat($analyzelocus, $FoT){
$analyzelocus//s:group[@nr=1]/text() || (
                                       if(empty($analyzelocus//s:group[@nr=2]) and $FoT = 't') then '99999' else (
                                       string(if(empty($analyzelocus//s:group[@nr=2])) then '0'  
                                                else if($analyzelocus//s:group[@nr=2]/text() = 'r') then '1' else '2')  || 
                                       string(if(empty($analyzelocus//s:group[@nr=3])) then '0' 
                                                    else if($analyzelocus//s:group[@nr=3]/text() = 'a')  then '1' else '2') ||
                                                   ( if (empty($analyzelocus//s:group[@nr=4])) then '999'  
                                                   else  (
                                                   if( number($analyzelocus//s:group[@nr=4]/text()) lt 10) 
                                                   then '0'|| $analyzelocus//s:group[@nr=4]/text() || '0'
                                                   else $analyzelocus//s:group[@nr=4]/text() || '0' ))))};
(:~ 
 : This function takes the value of @from or @to in locus and parses its content. 
 : assumed content of these attribute has the format  1, 1r, 1ra, 1r1, or 1ra1 where:
 : - the first numeric part is the folio
 : - r or v appear to indicate recto or verso of the folio. This is optional.
 : - a letter is used to indicate the column (here we take only a and b into consideration). This is optional.
 : - a number indicates the line number :)
declare function local:numericLocus($locus, $ForT){
  let $analyzelocus := analyze-string($locus, '(\d+)([rv])?([ab])?(\d+)?') 
  let $fromNumeric := local:numericLocusformat($analyzelocus, $ForT)
    return  format-number(number($fromNumeric), '00000000') };
(:this function takes an element ant ist context and look in the TEI encoded file for the relevant placement information, returning 
a locus element:)
declare function local:findplacement($unit){
if($unit/name() = 'ab') then  $unit/parent::t:layout/t:locus[1]
                        else if($unit/name() = 'msPart') 
                        then  $unit/t:physDesc/t:objectDesc/t:supportDesc/t:extent/t:locus[1]
                        else$unit/t:locus[1]};
(:This function formats the content of a unit to return the minimal information needed to print in the Syntaxe du Codex table:)
declare function local:formatvaluefortable($values, $elname){
for $v in $values 
return 
if($v/node()[1]/name()= $elname and $v/type/text() != 'CONT') 
then $v/type/text() ||' of ' 
||(if($elname='ab') then string($v/node()[1]/@type) else string($v/node()[1]/@xml:id)) || 
(if($elname= 'handNote') then ' ('  || string($v/node()[1]/@corresp)   || ') |' else ' |') 
else ()};
(:We first store the entire manuscript description into a variable:)
let $ms := doc('../../BetMes/Manuscripts/Ham/DabraLibanosHamGG1/DabraLibanosHamGG1.xml') 
(: We map into variables each path to a type of identifiable unit we are interested in:)
(:parts:)
let $UniMat := $ms//t:msPart
(:contents:)
let $UniContMain := $ms//t:msItem
(:additions:)
let $UniContAdd := $ms//t:additions//t:item[t:locus]
(:ruling:)
let $UniRegl := $ms//t:layout/t:ab[@type='ruling']
(:layout:)
let $UniMeP := $ms//t:layout
(:hands:)
let $UniHand := $ms//t:handNote
(:decorations:)
let $UniDec := $ms//t:decoNote[not(parent::t:binding)]
(:we group all the units in a sequence:)
let $all := ($UniMat | $UniContAdd | $UniContMain | $UniDec | $UniHand | $UniMeP | $UniRegl)
return
(:the heading of our table as a comma-separated values table:)
( 'boundary, UniMat, UniContMain, UniContAdd, UniDec, UniHand, UniMeP, UniRegl
',
(:we want to list all possible boundaries which are relevant. To do this we collect in a variable parsing all
units above the references of the units and store them as numeric values using the local function local:numericLocus() :)
let $boundaries :=    for $unit in $all 
                let $place := local:findplacement($unit)
                let $formatFromNumeric :=  local:numericLocus($place/@from, 'f')                
                let $formatToNumeric := local:numericLocus($place/@to, 't') 
                return  (   
                <boundary>{$place/@from}{$formatFromNumeric}</boundary>, 
                <boundary>{$place/@to}{$formatToNumeric}</boundary> )
(:We order the relevant boundaries and group them so that each value appears only once:)
let $orderboundaries := for $b in $boundaries group by $b order by $b return $b
(:We now go through each of the boundaries and look again at the units to populate a line in the table 
for a value for each of the types of units as per the heading of the table:)
for $b in $orderboundaries
let $nextb := $orderboundaries[index-of($orderboundaries,$b) + 1]
let $values := for $unit in $all 
                        let $place := local:findplacement($unit)
                        let $formatFromNumeric :=  local:numericLocus($place/@from, 'f')                
                        let $formatToNumeric := local:numericLocus($place/@to, 't') 
                        return
(: We can now check the values and determin by comparison to the current boundary if the unit is starting, continuing or ending :)
if(($formatFromNumeric le $nextb) and ($formatToNumeric ge $b))
then <val>{$unit}{$place}<type>{
            if($formatFromNumeric eq $b) then 'START'
            else if($formatToNumeric eq $b) then 'END'
            else 'CONT'}</type></val>  else ()
(:For each relevant unit we populate a small model excluding continuing units, and registering with some identifiable information
only the beginning and ends of units
We assume an @xml:id has been given to each relevant element, but not to ruling information, for which we only give the type (ruling):)
let $listvalues :=
<list>
<mspart>{local:formatvaluefortable($values, 'msPart')}</mspart>
<content>{local:formatvaluefortable($values, 'msItem')}</content>
<addition>{local:formatvaluefortable($values, 'item')}</addition>
<deco>{local:formatvaluefortable($values, 'decoNote')}</deco>
<hand>{local:formatvaluefortable($values, 'handNote')}</hand>
<layout>{local:formatvaluefortable($values, 'layout')}</layout>
<reg>{local:formatvaluefortable($values, 'ab')}</reg>
</list>
return
(:we can now return a row in our table sequencing the name of the buondary (the first of the eventually several values available, as a label)
and then the formatted list of values for relevant units :)
((:$b || ', ' ||:)
string($boundaries[.=$b][1]/@*) ||',' 
||string-join($listvalues/node(), ',') || '
')
(:the resulting line will look something like
1,START of p1 |,START of p1_i1 |,,,START of h8 (#p1_i1) |,START of layout1 |,START of ruling | START of ruling |
or
10vb18,,END of p2_i7 |,,,END of h9 (#p2) |,,
:)
)