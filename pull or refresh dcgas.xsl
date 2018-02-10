<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="3.0">
    <!-- Input: any document -->
    <!-- Parameters: as below -->
    <!-- Output: the specific files picked by the parameters that are found at the Digital Corpus for Greco-Arabic Studies -->
    <xsl:param name="dcgas-url" select="'https://www.graeco-arabic-studies.org/fileadmin/user_upload/texts.xml/'"/>
    <xsl:param name="prefixes-to-check" select="('psMenan-Gr')"/>
    <!--<xsl:param name="prefixes-to-check" select="('psArist-Gr', 'psArist-Ar')"/>-->
    <!--<xsl:param name="prefixes-to-check" select="('psMenan-Gr', 'psMenan-Ar')"/>-->
    <xsl:param name="from" select="1"/>
    <xsl:param name="to" select="40"/>
    <xsl:param name="refresh-only" as="xs:boolean" select="false()"/>
    <xsl:variable name="local-catalog" select="doc('catalog.xml')"/>
    
    <xsl:variable name="candidate-urls" as="element()*">
        <xsl:choose>
            <xsl:when test="$refresh-only">
                <xsl:for-each select="$local-catalog/collection/doc/@href">
                    <url src="{$dcgas-url || .}" target="{.}"/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$from to $to">
                    <xsl:variable name="this-number" select="format-number(.,'000')"/>
                    <xsl:for-each select="$prefixes-to-check">
                        <xsl:variable name="this-url" select="$dcgas-url || . || '_' || $this-number || '.xml'"/>
                        <xsl:variable name="target-url" select=". || '_' || $this-number || '.xml'"/>
                        <url src="{$this-url}" target="{$target-url}"/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:template match="/">
        <xsl:for-each select="$candidate-urls">
            <xsl:call-template name="results">
                <xsl:with-param name="source-url" select="@src"/>
                <xsl:with-param name="target-url" select="@target"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="results">
        <xsl:param name="source-url" as="xs:string"/>
        <xsl:param name="target-url" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="doc-available($source-url)">
                <xsl:if test="$refresh-only">
                    <xsl:message select="'Refreshing ' || $source-url"/>
                </xsl:if>
                <xsl:result-document href="orig/{$target-url}">
                    <xsl:document>
                        <xsl:copy-of select="doc($source-url)"/>
                    </xsl:document>
                </xsl:result-document>
            </xsl:when>
            <xsl:when test="unparsed-text-available($source-url)">
                <xsl:message select="'Bad XML at ' || $source-url"/>
                <xsl:result-document href="{$target-url || '_bad.txt'}" method="text">
                    <xsl:copy-of select="unparsed-text($source-url)"/>
                </xsl:result-document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$refresh-only">
                    <xsl:message select="'No file found at ' || $source-url"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>