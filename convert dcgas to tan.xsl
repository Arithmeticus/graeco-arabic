<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="#all" version="2.0">

    <!-- Input: Any original TEI.2 file from the Digital Corpus for Greco-Arabic Studies -->
    <!-- Output: a TAN-TEI version and one or more TAN-T versions under the tan directory -->
    <xsl:import href="../../TAN-2018/do%20things/get%20inclusions/convert.xsl"/>
    <xsl:import href="../../TAN-2018/do%20things/get%20inclusions/analysis%20of%20TEI.xsl"/>

    <xsl:output indent="yes"/>

    <!-- This stylesheet -->
    <xsl:variable name="stylesheet-iri"
        select="'tag:kalvesmaki.com,2014:stylesheet:convert-dcgas-to-tan'"/>
    <xsl:variable name="change-message" select="'Converted TEI.2 to TAN'"/>


    <!-- Input -->
    <xsl:param name="input-items" as="item()*" select="/"/>
    <xsl:variable name="input-has-multiple-work-versions"
        select="exists(/TEI.2/text/body/div1[@type = 'translation'])"/>

    <xsl:variable name="input-filename" select="tan:cfn(/)"/>
    <xsl:variable name="input-titleStmt" select="/TEI.2/teiHeader/fileDesc/titleStmt"/>
    <xsl:variable name="input-sourceDesc" select="/TEI.2/teiHeader/fileDesc/sourceDesc"/>
    <xsl:variable name="input-language" as="xs:language">
        <xsl:choose>
            <xsl:when test="/TEI.2/text/@lang = 'greek'">grc</xsl:when>
            <xsl:when test="/TEI.2/text/@lang = 'la'">lat</xsl:when>
            <xsl:when test="/TEI.2/text/@lang = 'arabic'">ara</xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="input-funder" select="/TEI.2/teiHeader//funder"/>
    <xsl:variable name="input-scriptum"
        select="tan:normalize-text(string-join(/TEI.2/teiHeader/fileDesc/sourceDesc//(author, title, date, editor)//text(), ' '))"/>
    <!-- The replace function below ensures that parenthetical qualifiers don't show up in the work description -->
    <xsl:variable name="input-work"
        select="
            tan:normalize-text(
            replace(string-join(/TEI.2/teiHeader/fileDesc/titleStmt//title//text(), ' '),'\s*\([^\)]+\)','')
            )"/>


    <xsl:template match="*" mode="input-pass-1 input-pass-1-leaf-divs" priority="-2">
        <xsl:variable name="this-name" select="name(.)"/>
        <xsl:element name="{$this-name}" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="@*" mode="input-pass-1 input-pass-1-leaf-divs">
        <xsl:copy/>
    </xsl:template>
    <xsl:template match="text()" mode="input-pass-1 input-pass-1-leaf-divs">
        <xsl:value-of select="tan:normalize-text(.)"/>
    </xsl:template>
    <xsl:template match="/*" mode="input-pass-1">
        <xsl:if test="$input-has-multiple-work-versions">
            <xsl:message>The input has multiple work versions that must be disentangled into separate files before processing</xsl:message>
        </xsl:if>
        <xsl:text>&#xa;</xsl:text>
        <xsl:comment>&lt;?xml-model href="http://textalign.net/release/TAN-2018/schemas/TAN-TEI.rnc" type="application/relax-ng-compact-syntax"?>
&lt;?xml-model href="http://textalign.net/release/TAN-2018/schemas/TAN-TEI.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?></xsl:comment>
        <xsl:text>&#xa;</xsl:text>
        <xsl:element name="TEI" namespace="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="id"
                select="concat('tag:kalvesmaki.com,2014:conversion:tan-tei:dcgas-', $input-filename)"/>
            <xsl:attribute name="TAN-version">2018</xsl:attribute>
            <xsl:apply-templates select="teiHeader" mode="#current"/>
            <xsl:copy-of select="$tan-head"/>
            <xsl:apply-templates select="text" mode="#current"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="teiHeader" mode="input-pass-1">
        <teiHeader xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:copy-of select="@* except (@type, @status)"/>
            <xsl:apply-templates mode="#current"/>
        </teiHeader>
    </xsl:template>
    <xsl:template match="sourceDesc" mode="input-pass-1">
        <publicationStmt xmlns="http://www.tei-c.org/ns/1.0">
            <p/>
        </publicationStmt>
        <sourceDesc xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates mode="#current"/>
        </sourceDesc>
    </xsl:template>
    <xsl:template match="@default" mode="input-pass-1">
        <xsl:attribute name="default" select="replace(., 'NO', 'false')"/>
    </xsl:template>
    <xsl:template match="sourceDesc/p | encodingDesc | profileDesc | imprint/title" mode="input-pass-1">
        <xsl:comment>
            <xsl:value-of select="tan:xml-to-string(.)"/>
        </xsl:comment>
    </xsl:template>
    <xsl:variable name="input-persons" as="element()*">
        <xsl:if test="$input-language = ('grc', 'lat')">
            <person xml:id="mjs" which="Mark J. Schiefsky"/>
            <person xml:id="grc" which="Gregory R. Crane"/>
        </xsl:if>
        <xsl:if test="$input-language = 'ara'">
            <person xml:id="uv" which="Uwe Vagelpohl"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="tan-head" as="element()">
        <head>
            <name>
                <xsl:value-of
                    select="concat($input-titleStmt/title, ' by ', $input-titleStmt/author, ' in ', $input-language, ' published ', $input-sourceDesc//date)"
                />
            </name>
            <license which="public zero"/>
            <licensor who="{$input-persons/@xml:id}"/>
            <key>
                <IRI>tag:kalvesmaki.com,2014:tan-key:dcgas</IRI>
                <name>Definitions of entities mentioned in DCGAS files</name>
                <location href="key/DCGAS.TAN-key.xml" when-accessed="{current-date()}"/>
            </key>
            <source which="{tan:possible-bibliography-id($input-scriptum)}"/>
            <definitions>
                <work which="{$input-work}"/>
                <xsl:for-each select="distinct-values(/TEI.2/text/body//(div, div1, div2, div3, milestone)/@type)">
                    <xsl:variable name="predefined-type">
                        <xsl:choose>
                            <xsl:when test="false()"/>
                            <xsl:otherwise>
                                <xsl:value-of select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <div-type xml:id="{.}" which="{$predefined-type}"/>
                </xsl:for-each>
                <algorithm xml:id="xslt">
                    <IRI>
                        <xsl:value-of select="$stylesheet-iri"/>
                    </IRI>
                    <name>Stylesheet for converting TEI.2 from the Digital Corpus for Greco-Arabic
                        Studies to TAN-TEI</name>
                </algorithm>
                <xsl:copy-of select="$input-persons"/>
                <role xml:id="stylesheet" which="stylesheet"/>
                <role xml:id="editor" which="editor"/>
                <xsl:if test="exists($input-funder)">
                    <role xml:id="funder" which="funder"/>
                    <xsl:for-each select="$input-funder">
                        <organization xml:id="{lower-case(tan:acronym(.))}" which="{.}"/>
                    </xsl:for-each>
                </xsl:if>
            </definitions>
            <resp who="xslt" roles="stylesheet"/>
            <resp who="{$input-persons/@xml:id}" roles="editor"/>
            <xsl:if test="exists($input-funder)">
                <resp roles="funder"
                    who="{string-join(for $i in $input-funder return lower-case(tan:acronym($i)),' ')}"
                />
            </xsl:if>
            <change who="xslt" when="{current-date()}">Converted from original file at <xsl:value-of
                select="$input-filename"/></change>
        </head>
    </xsl:variable>
    
    
    
    <xsl:template match="text" mode="input-pass-1">
        <text xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:copy-of select="@* except (@lang, @id)"/>
            <xsl:apply-templates mode="#current"/>
        </text>
    </xsl:template>
    <xsl:template match="body" mode="input-pass-1">
        <xsl:variable name="majority-children"
            select="
                tan:most-common-item(for $i in *
                return
                    local-name($i))"
        />
        <body xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="xml:lang" select="$input-language"/>
            <xsl:apply-templates mode="#current">
                <xsl:with-param name="majority-children" select="$majority-children"/>
            </xsl:apply-templates>
        </body>
    </xsl:template>
    <xsl:template match="body/text()[matches(.,'\S')]" mode="input-pass-1">
        <div xmlns="http://www.tei-c.org/ns/1.0" type="section" n="{count(preceding-sibling::text()[matches(.,'\S')]) + 1}">
            <ab><xsl:value-of select="normalize-unicode(.)"/></ab>
        </div>
    </xsl:template>
    <!--<xsl:template match="body//*" priority="-1" mode="input-pass-1">
        <!-\- default treatment of elements that are not in leaf divs and are themselves not divs -\->
        <xsl:variable name="this-element-name" select="local-name(.)"/>
        <div xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:attribute name="type" select=""/>
            <xsl:attribute name="n" select=""></xsl:attribute>
            <xsl:copy-of select="(@n, @type)"/>
            <xsl:apply-templates mode="#current"/>
        </div>
    </xsl:template>-->
    
    
    <xsl:template match="body//*" priority="-1" mode="input-pass-1">
        <!-- these are general rules for non divs that find themselves in non-leaf divs -->
        <xsl:param name="majority-children"/>
        <xsl:variable name="this-element-name" select="name()"/>
        <xsl:variable name="there-are-many" select="count(../*[name() = $this-element-name]) gt 1"
            as="xs:boolean"/>
        <xsl:variable name="this-pos"
            select="count(preceding-sibling::*[name() = $this-element-name]) + 1"/>
        <xsl:variable name="this-type" as="xs:string">
            <xsl:choose>
                <xsl:when test="self::head">title</xsl:when>
                <xsl:when
                    test="parent::body and not(exists(preceding-sibling::*[local-name() = $this-element-name]))"
                    >prologue</xsl:when>
                <xsl:when
                    test="parent::body and not(exists(following-sibling::*[local-name() = $this-element-name]))"
                    >epilogue</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$this-element-name"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="this-n"
            select="
                if ($this-element-name = $majority-children) then
                    xs:string($this-pos)
                else
                    concat($this-type,
                    if (($this-pos gt 1) and $there-are-many) then
                        xs:string($this-pos)
                    else
                        ())"/>
        <xsl:choose>
            <xsl:when test="$this-element-name = $milestoneLike-element-info//@name">
                <xsl:element name="{$this-element-name}" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <div xmlns="http://www.tei-c.org/ns/1.0" type="{$this-type}" n="{$this-n}">
                    <!-- By default, we make this anonymous, because the semantics of the element that's being processed are trickling up into the <div> -->
                    <ab>
                        <xsl:apply-templates mode="#current"/>
                    </ab>
                    <!--<xsl:element name="{$this-element-name}" namespace="http://www.tei-c.org/ns/1.0">
                    </xsl:element>-->
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="div | div1 | div2 | div3 | div4 | div5" priority="1" mode="input-pass-1 input-pass-1-leaf-divs">
        <xsl:variable name="descendant-text-nodes" select=".//text()"/>
        <xsl:variable name="text-norm" select="tan:normalize-text(string-join($descendant-text-nodes,''))"/>
        <!-- mind you, this looks for divs that have elements; there are cases here where empty <div>s are used like anchors -->
        <xsl:variable name="has-divs" select="exists(*[matches(local-name(), '^div')][*])"/>
        <xsl:choose>
            <!-- If a div is empty, it should be skipped -->
            <xsl:when test="exists($descendant-text-nodes) and not(matches($text-norm, '\S'))">
                <xsl:comment><xsl:value-of select="tan:xml-to-string(.)"/></xsl:comment>
            </xsl:when>
            <xsl:when test="exists(*) and $has-divs">
                <div xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="(@n, @type)"/>
                    <xsl:apply-templates mode="#current"/>
                </div>
            </xsl:when>
            <xsl:when test="exists(*)">
                <div xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="(@n, @type)"/>
                    <xsl:apply-templates mode="input-pass-1-leaf-divs"/>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <milestone xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="@* except @n"/>
                    <xsl:attribute name="unit" select="@n"/>
                </milestone>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Pass 1 for leaf div content -->
    <xsl:template match="head" mode="input-pass-1-leaf-divs">
        <xsl:choose>
            <xsl:when test="exists(preceding-sibling::p)">
                <ab type="title" xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </ab>
            </xsl:when>
            <xsl:otherwise>
                <head xmlns="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates mode="#current"/>
                </head>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tr" mode="input-pass-1-leaf-divs">
        <row xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </row>
    </xsl:template>
    <xsl:template match="td" mode="input-pass-1-leaf-divs">
        <cell xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="#current"/>
        </cell>
    </xsl:template>


    <!-- PASS 2 -->
    <xsl:variable name="div-type-glossary" select="tan:glossary('div-type')"/>
    <xsl:variable name="div-type-glossary-for-tei-element" select="$div-type-glossary[tan:name[matches(.,'^tei ')]]"/>
    
    <xsl:template match="tan:definitions" mode="input-pass-2">
        <xsl:variable name="all-div-types-used" select="root()/tei:TEI/tei:text/tei:body//tei:div/@type"/>
        <xsl:variable name="all-div-types-defined" select="tan:div-type/@xml:id"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="node()"/>
            <xsl:for-each
                select="distinct-values($all-div-types-used[not(. = $all-div-types-defined)])">
                <xsl:variable name="this-div-type" select="."/>
                <xsl:variable name="default-match" select="$div-type-glossary[tan:name = $this-div-type]"/>
                <xsl:variable name="tei-match" select="$div-type-glossary-for-tei-element[tan:name = concat('tei ', $this-div-type)]"/>
                <xsl:variable name="this-which" as="xs:string">
                    <xsl:choose>
                        <xsl:when test="exists($default-match)">
                            <xsl:value-of select="$default-match/tan:name[1]"/>
                        </xsl:when>
                        <xsl:when test="exists($tei-match)">
                            <xsl:value-of select="$tei-match/tan:name[1]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <div-type xml:id="{.}" which="{$this-which}"/>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:pb | tei:lb | tei:cb | tei:milestone" mode="input-pass-2">
        <xsl:variable name="preceding-text" select="preceding-sibling::node()[1]/self::text()"/>
        <xsl:variable name="following-text" select="following-sibling::node()[1]/self::text()"/>
        <xsl:variable name="adjacent-anchor" as="xs:string*">
            <xsl:if test="exists($preceding-text)">
                <xsl:analyze-string select="$preceding-text" regex="({$break-marker-regex})\s*$">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:if>
            <xsl:if test="exists($following-text)">
                <xsl:analyze-string select="$following-text" regex="^\s*({$break-marker-regex})">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:if>
        </xsl:variable>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:if test="exists($adjacent-anchor)">
                <xsl:attribute name="rend" select="$adjacent-anchor"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    
    
    <!-- very specific errata -->
    <xsl:template mode="input-pass-2"
        match="/tei:TEI[@id = 'tag:kalvesmaki.com,2014:conversion:tan-tei:dcgas-psArist-Gr_005']/tei:text/tei:body/tei:div[5]">
        <xsl:copy>
            <xsl:attribute name="n" select="'5'"/>
            <xsl:copy-of select="@* except @n"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="text()" mode="input-pass-2">
        <xsl:choose>
            <xsl:when test="preceding-sibling::*[1][local-name() = ('pb', 'lb', 'cb', 'milestone')]">
                <xsl:analyze-string select="." regex="^\s*({$break-marker-regex})">
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:when test="following-sibling::*[1][local-name() = ('pb', 'lb', 'cb', 'milestone')]">
                <xsl:analyze-string select="." regex="({$break-marker-regex})\s*$">
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    

    <xsl:template match="/" priority="5">
        <!--<xsl:copy-of select="$input-pass-1"/>-->
        <xsl:copy-of select="$input-pass-2"/>
        <!--<diagnostics xmlns="">
            <!-\-<xsl:copy-of select="$input-pass-2"/>-\->
        </diagnostics>-->
    </xsl:template>




</xsl:stylesheet>
