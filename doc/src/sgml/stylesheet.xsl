<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version='1.0'
                xmlns="http://www.w3.org/1999/xhtml">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/xhtml/chunk.xsl"/>
<xsl:include href="stylesheet-common.xsl" />
<xsl:include href="stylesheet-html-common.xsl" />
<xsl:include href="stylesheet-speedup-xhtml.xsl" />


<!-- Parameters -->
<xsl:param name="base.dir" select="'html/'"></xsl:param>
<xsl:param name="use.id.as.filename" select="'1'"></xsl:param>
<xsl:param name="generate.legalnotice.link" select="1"></xsl:param>
<xsl:param name="chunk.first.sections" select="1"/>
<xsl:param name="chunk.quietly" select="1"></xsl:param>
<xsl:param name="admon.style"></xsl:param>  <!-- handled by CSS stylesheet -->


<!-- copy images to the output directory, so the output is self contained -->
<xsl:template match="imageobject">
  <xsl:call-template name="write-image"/>
  <xsl:apply-templates select="imagedata"/>
</xsl:template>

<!-- strip directory name from image filerefs -->
<xsl:template match="imagedata/@fileref">
 <xsl:value-of select="substring-after(., '/')"/>
</xsl:template>


<!--
Customization of header
- add Up and Home links
- add tool tips to links

(overrides html/chunk-common.xsl)
-->

<!-- begin tree nav additions -->
<xsl:template match="book|preface|part|chapter|appendix|sect1[title]|sect2[title]|sect3[title]|sect4[title]|refentry" mode="tree-nav">
  <xsl:param name="source-node" select="/" />
  <xsl:variable name="self-id" select="generate-id()" />
  <xsl:variable name="source-id" select="generate-id($source-node)" />
  <li>
    <xsl:choose>
      <xsl:when test="$source-id = $self-id">
        <xsl:attribute name="class">current</xsl:attribute>
      </xsl:when>
      <xsl:when test="$source-node/ancestor-or-self::*[generate-id() = $self-id]">
        <xsl:attribute name="class">ancestor</xsl:attribute>
      </xsl:when>
    </xsl:choose>
    <a>
      <xsl:attribute name="href">
        <xsl:call-template name="href.target">
          <xsl:with-param name="object" select="." />
        </xsl:call-template>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="name() = 'book'">
          PostgreSQL docs
        </xsl:when>
        <xsl:when test="name() = 'refentry'">
          <xsl:copy-of select="refmeta/refentrytitle" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="title" mode="title.markup" />
        </xsl:otherwise>
      </xsl:choose>
    </a>
    <xsl:if test="name() = 'book'">
      <div class="pg-v-switch">
        <span class="pg-v pg-v-selected" href="#">16</span>
        <xsl:text xml:space="preserve"> </xsl:text>
        <a class="pg-v" href="#">15</a>
        <xsl:text xml:space="preserve"> </xsl:text>
        <a class="pg-v" href="#">14</a>
      </div>
    </xsl:if>
  </li>
  <xsl:if test="$source-node/ancestor-or-self::*[generate-id() = $self-id]">  
    <ul>
      <xsl:apply-templates mode="tree-nav">
        <xsl:with-param name="source-node" select="$source-node" />
      </xsl:apply-templates>
    </ul>
  </xsl:if>
</xsl:template>

<xsl:template match="text()|@*" mode="tree-nav"></xsl:template>
<!-- end tree nav additions -->

<xsl:template name="header.navigation">
  <xsl:param name="prev" select="/foo"/>
  <xsl:param name="next" select="/foo"/>
  <xsl:param name="nav.context"/>

  <xsl:variable name="home" select="/*[1]"/>
  <xsl:variable name="up" select="parent::*"/>

  <xsl:variable name="row1" select="$navig.showtitles != 0"/>
  <xsl:variable name="row2" select="count($prev) &gt; 0
                                    or (count($up) &gt; 0
                                        and $navig.showtitles != 0)
                                    or count($next) &gt; 0"/>
  
  <!-- begin tree nav additions -->
  <ul id="tree-nav">
    <xsl:apply-templates select="/" mode="tree-nav">
      <xsl:with-param name="source-node" select="." />
    </xsl:apply-templates>

    <!-- https://stackoverflow.com/questions/14389566/stop-css-transition-from-firing-on-page-load -->
    <script><xsl:text xml:space="preserve"> </xsl:text></script>
  </ul>
  <script>
    const tn = document.getElementById('tree-nav');
    addEventListener('beforeunload', function () { sessionStorage.setItem('tny', String(tn.scrollTop)); });
    addEventListener('load', function () { tn.scrollTop = parseInt(sessionStorage.getItem('tny') || '0', 10); });
  </script>
  <!-- end tree nav additions -->

  <xsl:if test="$suppress.navigation = '0' and $suppress.header.navigation = '0'">
    <div class="navheader">
      <xsl:if test="$row1 or $row2">
        <table width="100%" summary="Navigation header">
          <xsl:if test="$row1">
            <tr>
              <th colspan="5" align="center">
                <xsl:apply-templates select="." mode="object.title.markup"/>
              </th>
            </tr>
          </xsl:if>

          <xsl:if test="$row2">
            <tr>
              <td width="10%" align="{$direction.align.start}">
                <xsl:if test="count($prev)>0">
                  <a accesskey="p">
                    <xsl:attribute name="href">
                      <xsl:call-template name="href.target">
                        <xsl:with-param name="object" select="$prev"/>
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:attribute name="title">
                      <xsl:apply-templates select="$prev" mode="object.title.markup"/>
                    </xsl:attribute>
                    <xsl:call-template name="navig.content">
                      <xsl:with-param name="direction" select="'prev'"/>
                    </xsl:call-template>
                  </a>
                </xsl:if>
                <xsl:text>&#160;</xsl:text>
              </td>
              <td width="10%" align="{$direction.align.start}">
                <xsl:choose>
                  <xsl:when test="count($up)&gt;0">
                    <a accesskey="u">
                      <xsl:attribute name="href">
                        <xsl:call-template name="href.target">
                          <xsl:with-param name="object" select="$up"/>
                        </xsl:call-template>
                      </xsl:attribute>
                      <xsl:attribute name="title">
                        <xsl:apply-templates select="$up" mode="object.title.markup"/>
                      </xsl:attribute>
                      <xsl:call-template name="navig.content">
                        <xsl:with-param name="direction" select="'up'"/>
                      </xsl:call-template>
                    </a>
                  </xsl:when>
                  <xsl:otherwise>&#160;</xsl:otherwise>
                </xsl:choose>
              </td>
              <th width="60%" align="center">
                <xsl:choose>
                  <xsl:when test="count($up) > 0
                                  and $navig.showtitles != 0">
                    <xsl:apply-templates select="$up" mode="object.title.markup"/>
                  </xsl:when>
                  <xsl:otherwise>&#160;</xsl:otherwise>
                </xsl:choose>
              </th>
              <td width="10%" align="{$direction.align.end}">
                <xsl:choose>
                  <xsl:when test="$home != . or $nav.context = 'toc'">
                    <a accesskey="h">
                      <xsl:attribute name="href">
                        <xsl:call-template name="href.target">
                          <xsl:with-param name="object" select="$home"/>
                        </xsl:call-template>
                      </xsl:attribute>
                    <xsl:attribute name="title">
                      <xsl:apply-templates select="$home" mode="object.title.markup"/>
                    </xsl:attribute>
                      <xsl:call-template name="navig.content">
                        <xsl:with-param name="direction" select="'home'"/>
                      </xsl:call-template>
                    </a>
                    <xsl:if test="$chunk.tocs.and.lots != 0 and $nav.context != 'toc'">
                      <xsl:text>&#160;|&#160;</xsl:text>
                    </xsl:if>
                  </xsl:when>
                  <xsl:otherwise>&#160;</xsl:otherwise>
                </xsl:choose>
              </td>
              <td width="10%" align="{$direction.align.end}">
                <xsl:text>&#160;</xsl:text>
                <xsl:if test="count($next)>0">
                  <a accesskey="n">
                    <xsl:attribute name="href">
                      <xsl:call-template name="href.target">
                        <xsl:with-param name="object" select="$next"/>
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:attribute name="title">
                      <xsl:apply-templates select="$next" mode="object.title.markup"/>
                    </xsl:attribute>
                    <xsl:call-template name="navig.content">
                      <xsl:with-param name="direction" select="'next'"/>
                    </xsl:call-template>
                  </a>
                </xsl:if>
              </td>
            </tr>
          </xsl:if>
        </table>
      </xsl:if>
      <xsl:if test="$header.rule != 0">
        <hr/>
      </xsl:if>
    </div>
  </xsl:if>
</xsl:template>


<!--
Customization of footer
- don't hide redundant Up link
- add tool tips to links

(overrides html/chunk-common.xsl)
-->
<xsl:template name="footer.navigation">
  <xsl:param name="prev" select="/foo"/>
  <xsl:param name="next" select="/foo"/>
  <xsl:param name="nav.context"/>

  <xsl:variable name="home" select="/*[1]"/>
  <xsl:variable name="up" select="parent::*"/>

  <xsl:variable name="row1" select="count($prev) &gt; 0
                                    or count($up) &gt; 0
                                    or count($next) &gt; 0"/>

  <xsl:variable name="row2" select="($prev and $navig.showtitles != 0)
                                    or (generate-id($home) != generate-id(.)
                                        or $nav.context = 'toc')
                                    or ($chunk.tocs.and.lots != 0
                                        and $nav.context != 'toc')
                                    or ($next and $navig.showtitles != 0)"/>

  <xsl:if test="$suppress.navigation = '0' and $suppress.footer.navigation = '0'">
    <div class="navfooter">
      <xsl:if test="$footer.rule != 0">
        <hr/>
      </xsl:if>

      <xsl:if test="$row1 or $row2">
        <table width="100%" summary="Navigation footer">
          <xsl:if test="$row1">
            <tr>
              <td width="40%" align="{$direction.align.start}">
                <xsl:if test="count($prev)>0">
                  <a accesskey="p">
                    <xsl:attribute name="href">
                      <xsl:call-template name="href.target">
                        <xsl:with-param name="object" select="$prev"/>
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:attribute name="title">
                      <xsl:apply-templates select="$prev" mode="object.title.markup"/>
                    </xsl:attribute>
                    <xsl:call-template name="navig.content">
                      <xsl:with-param name="direction" select="'prev'"/>
                    </xsl:call-template>
                  </a>
                </xsl:if>
                <xsl:text>&#160;</xsl:text>
              </td>
              <td width="20%" align="center">
                <xsl:choose>
                  <xsl:when test="count($up)&gt;0">
                    <a accesskey="u">
                      <xsl:attribute name="href">
                        <xsl:call-template name="href.target">
                          <xsl:with-param name="object" select="$up"/>
                        </xsl:call-template>
                      </xsl:attribute>
                      <xsl:attribute name="title">
                        <xsl:apply-templates select="$up" mode="object.title.markup"/>
                      </xsl:attribute>
                      <xsl:call-template name="navig.content">
                        <xsl:with-param name="direction" select="'up'"/>
                      </xsl:call-template>
                    </a>
                  </xsl:when>
                  <xsl:otherwise>&#160;</xsl:otherwise>
                </xsl:choose>
              </td>
              <td width="40%" align="{$direction.align.end}">
                <xsl:text>&#160;</xsl:text>
                <xsl:if test="count($next)>0">
                  <a accesskey="n">
                    <xsl:attribute name="href">
                      <xsl:call-template name="href.target">
                        <xsl:with-param name="object" select="$next"/>
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:attribute name="title">
                      <xsl:apply-templates select="$next" mode="object.title.markup"/>
                    </xsl:attribute>
                    <xsl:call-template name="navig.content">
                      <xsl:with-param name="direction" select="'next'"/>
                    </xsl:call-template>
                  </a>
                </xsl:if>
              </td>
            </tr>
          </xsl:if>

          <xsl:if test="$row2">
            <tr>
              <td width="40%" align="{$direction.align.start}" valign="top">
                <xsl:if test="$navig.showtitles != 0">
                  <xsl:apply-templates select="$prev" mode="object.title.markup"/>
                </xsl:if>
                <xsl:text>&#160;</xsl:text>
              </td>
              <td width="20%" align="center">
                <xsl:choose>
                  <xsl:when test="$home != . or $nav.context = 'toc'">
                    <a accesskey="h">
                      <xsl:attribute name="href">
                        <xsl:call-template name="href.target">
                          <xsl:with-param name="object" select="$home"/>
                        </xsl:call-template>
                      </xsl:attribute>
                      <xsl:attribute name="title">
                        <xsl:apply-templates select="$home" mode="object.title.markup"/>
                      </xsl:attribute>
                      <xsl:call-template name="navig.content">
                        <xsl:with-param name="direction" select="'home'"/>
                      </xsl:call-template>
                    </a>
                    <xsl:if test="$chunk.tocs.and.lots != 0 and $nav.context != 'toc'">
                      <xsl:text>&#160;|&#160;</xsl:text>
                    </xsl:if>
                  </xsl:when>
                  <xsl:otherwise>&#160;</xsl:otherwise>
                </xsl:choose>

                <xsl:if test="$chunk.tocs.and.lots != 0 and $nav.context != 'toc'">
                  <a accesskey="t">
                    <xsl:attribute name="href">
                      <xsl:value-of select="$chunked.filename.prefix"/>
                      <xsl:apply-templates select="/*[1]"
                                           mode="recursive-chunk-filename">
                        <xsl:with-param name="recursive" select="true()"/>
                      </xsl:apply-templates>
                      <xsl:text>-toc</xsl:text>
                      <xsl:value-of select="$html.ext"/>
                    </xsl:attribute>
                    <xsl:call-template name="gentext">
                      <xsl:with-param name="key" select="'nav-toc'"/>
                    </xsl:call-template>
                  </a>
                </xsl:if>
              </td>
              <td width="40%" align="{$direction.align.end}" valign="top">
                <xsl:text>&#160;</xsl:text>
                <xsl:if test="$navig.showtitles != 0">
                  <xsl:apply-templates select="$next" mode="object.title.markup"/>
                </xsl:if>
              </td>
            </tr>
          </xsl:if>
        </table>
      </xsl:if>
    </div>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
