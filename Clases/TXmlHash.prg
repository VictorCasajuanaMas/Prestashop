//----------------------------------------------------------------------------//
// Author: Cristobal Navarro
// Date:  November - 2018
// Use to Xml files / strings and convert to JSON-HASH
//----------------------------------------------------------------------------//


#include "Fivewin.ch"
#Include "hbmxml.ch"

//#require "hbmxml"

//----------------------------------------------------------------------------//

Static lMxml_Error := .F.
Static cMxml_Error := ""

//----------------------------------------------------------------------------//

Function FE_XmlToHash( cFile, cXml, cElement, lRepeat, lCDataNod ) 

   local oRoot

   hb_default( @cFile    , ""  )
   hb_default( @cXml     , ""  )
   hb_default( @cElement , ""  )
   hb_default( @lRepeat  , .F. )

   // Test with file
   if !Empty( cFile )
      if Empty( cElement )
         oRoot   := TXmlToHash():New( cFile, , , lRepeat, lCDataNod )
      else
         // Test for search key
         oRoot   := TXmlToHash():New( cFile, , cElement, lRepeat, lCDataNod )
      endif
   endif
   
   // Test from string
   if !Empty( cXml )
      if Empty( cElement )
         oRoot   := TXmlToHash():New( , cXml, , lRepeat, lCDataNod )
      else
         // Test for search key
         oRoot   := TXmlToHash():New( , cXml, cElement, lRepeat, lCDataNod )
      endif
   endif

   if !lMxml_Error
      oRoot:AllValues()
   else
      ? cMxml_Error
   endif

Return oRoot 

//----------------------------------------------------------------------------//
// Author: Cristobal Navarro
// Date:  November - 2018
// Use to Xml files / strings and convert to JSON-HASH
//----------------------------------------------------------------------------//

CLASS TXmlToHash

   DATA oRoot
   DATA hHash       INIT { => }
   DATA cXml        INIT ""
   DATA cXmlString  INIT ""
   DATA cValString  INIT ""
   DATA aPairsVals  INIT {}
   DATA lRepeat     INIT .F.
   DATA lDataNode   INIT .F.

   METHOD New( cFile, cXml, cElement, lRepeat ) CONSTRUCTOR
   METHOD End()
   METHOD AllValues( oXml )
   METHOD HashToXml( hHash, cFileXml, cElement, lWrite )
   METHOD JsonToXml( cFileJson, cJson, cFileXml )
   METHOD NodeToHash( oNode, hHash )
   METHOD XmlToHash( pRoot, cElement )
   METHOD XmlToJson( cFileJson, lWrite )
   METHOD GetAllAttributes( hElem )

ENDCLASS

//----------------------------------------------------------------------------//
// cFile: file to convert
// cXml:  string to convert
// cElement: key to search for begining convert
// lRepeat: allow repeat keys
//----------------------------------------------------------------------------//

METHOD New( cFile, cXml, cElement, lRepeat, lCDataNod ) CLASS TXmlToHash

   hb_default( @cFile     , ""  )
   hb_default( @cXml      , ""  )
   hb_default( @cElement  , ""  )
   hb_default( @lRepeat   , .F. )
   hb_default( @lCDataNod , .F. )

   ::lDataNode       := lCDataNod
   if !Empty( cFile ) .and. File( cFile )
      cXMl  := hb_MemoRead( cFile )
   endif
   if !Empty( cXml )
      //![CDATA[<?xml version="1.0" encoding="UTF-8"?>
      if !Empty( At( '![CDATA[<?xml version="1.0" encoding="UTF-8"?>', cXml ) )
      cXml   := StrTran( cXml, '<![CDATA[<?xml version="1.0" encoding="UTF-8"?>', if( ::lDataNode, "<CDATA>", "![CDATA[" ) )
      cXml   := StrTran( cXml, "]]>", if( ::lDataNode, "</CDATA>", "" ) )
      else
      cXml   := StrTran( cXml, "<![CDATA[", if( ::lDataNode, "<CDATA>", "![CDATA[" ) )
      cXml   := StrTran( cXml, "]]>", if( ::lDataNode, "</CDATA>", "" ) )
      endif
      ::cXml := cXml
   endif

   if !Empty( cXml )
      MxmlSetWrapMargin( 0 )    // Default: 75
      MxmlSetErrorCallback( @MxmlError() )
      ::lRepeat    := lRepeat
      ::oRoot      := MxmlLoadString( NIL, cXml, @uType_Callback() )
      if !lMxml_Error
         ::hHash      := ::XMLtoHash( ::oRoot, cElement )
         ::cXmlString := MxmlSaveAllocString( ::oRoot, MXML_OPAQUE_CALLBACK )
      endif
   endif

Return Self

//----------------------------------------------------------------------------//
// Destructor object
//----------------------------------------------------------------------------//

METHOD End() CLASS TXmlToHash

   MxmlDelete( ::oRoot )

Return nil

//----------------------------------------------------------------------------//
// Convert hash array to xml string and allow save to file
//----------------------------------------------------------------------------//

METHOD HashToXml( hHash, cFileXml, cElement, lWrite ) CLASS TXmlToHash

   Local x           := 0
   Local hKey        := {=>}
   Local aTmp        := {}
   Local aKeys       := {}
   Local aVals       := {}
   hb_default( @cFileXml  , "HASHTOXML.XML" )
   hb_default( @hHash     , ::hHash         )
   hb_default( @cElement  , "hashxml"       )
   hb_default( @lWrite    , .T.             )

   ::cXml            := '<?xml version="1.0" encoding="UTF-8"?>' + CRLF
   ::cXml            += '#element#' + CRLF

   if Empty( At( Chr( 13 ), ::cXml ) )
      ::cXml         := StrTran( ::cXml, Chr( 10 ), CRLF )
   endif

   //XBrowse( hHash )

   if Valtype( hHash ) == "H"
      aKeys := hb_hKeys( hHash )
      aVals := hb_hValues( hHash )
      //Hb_HEval( hHash, { | k, v, i | AAdd( aTmp, { k, v, i } ) } )
      if Len( aKeys ) > 1
         ::cXml         := StrTran( ::cXml, "#element#", "<" + AllTrim( cElement ) + ">" )
      else
         if Len( aKeys ) > 0
            ::cXml      := StrTran( ::cXml, "#element#", "<" + AllTrim( aKeys[ 1 ] ) + ">" )
         else
            ::cXml      := ""
         endif
      endif
   else
      if Valtype( hHash ) == "A" .and. Len( hHash ) >= 1
         if Valtype( hHash[ 1 ] ) == "H"
            aKeys := hb_hKeys( hHash[ 1 ] )
            aVals := hb_hValues( hHash[ 1 ] )
            //Hb_HEval( hHash, { | k, v, i | AAdd( aTmp, { k, v, i } ) } )
            if Len( aKeys ) > 1
               ::cXml         := StrTran( ::cXml, "#element#", "<" + AllTrim( cElement ) + ">" )
            else
               if Len( aKeys ) > 0
                  ::cXml      := StrTran( ::cXml, "#element#", "<" + AllTrim( aKeys[ 1 ] ) + ">" )
               else
                  ::cXml      := ""
               endif
            endif
         endif
      endif
   endif
   For x = 1 to Len( aKeys )
      if Len( aKeys ) > 1
         ::cXml      += "<" + aKeys[ x ] + ">" + CRLF
      endif
      if Valtype( aVals[ x ] ) == "H"
         ::cXml      += HHashToXml( aVals[ x ] )
         ::cXml      += "</" + aKeys[ x ] + ">" + CRLF
      else
         if Valtype( aVals[ x ] ) == "A"
            ::cXml   += HHashToXml( aVals[ x ] )
            ::cXml   += "</" + aKeys[ x ] + ">" + CRLF
         else
            ::cXml   += "</" + aKeys[ x ] + ">" + CRLF
         endif
      endif
   Next x
   if !Empty( cFileXml )
      MemoWrit( cFileXml, ::cXml )   // , lEof   
   endif

Return ::cXml

//----------------------------------------------------------------------------//
// Recursive function for iteration in nodes
//----------------------------------------------------------------------------//

Static Function HHashToXml( hHash ) //, cXml )

   Local x           := 0
   Local y           := 0
   Local hKey
   Local aTmp        := {}
   Local aKeys       := {}
   Local aVals       := {}
   Local nLen
   Local cTmp        := ""
   Local cKey        := ""
   Local cXml        := ""

   if Valtype( hHash ) == "H"
      aKeys := hb_hKeys( hHash )
      aVals := hb_hValues( hHash )
      //XBrowse( hHash )
      //Hb_HEval( hHash, { | k, v, i | AAdd( aTmp, { k, v, i } ) } )
   else
      if Valtype( hHash ) == "A" .and. Len( hHash ) >= 1
         if Valtype( hHash[ 1 ] ) == "H"
            aKeys := hb_hKeys( hHash[ 1 ] )
            aVals := hb_hValues( hHash[ 1 ] )
         endif
      endif
   endif

   For y = 1 to Len( hHash )
      aKeys := hb_hKeys( hHash[ y ] )
      aVals := hb_hValues( hHash[ y ] )
      For x = 1 to Len( aKeys )
         hKey        := aVals[ x ]
         if Valtype( hKey ) == "H"
            if !Empty( At( "@", aKeys[ x ] ) )
               // Atributos
               // HAttributes( aKeys, aVals, x )
            else
               cXml     += "<" + aKeys[ x ] + ">"
               // HAttributes( aKeys, aVals, x )
               cXml     += HHashToXml( hKey ) //aVals[ x ] )
               cXml     += "</" + aKeys[ x ] + ">" + CRLF
            endif
         else
            if Valtype( hKey ) == "A"
               if !Empty( At( "@", aKeys[ x ] ) )
                  // Atributos
                  //HAttributes( aKeys, aVals, x )
               else
                  //cKey     := aKeys[ x ]
                  cXml  += "<" + aKeys[ x ] + ">" + CRLF
                  //HAttributes( aKeys, aVals, x )
                  cXml  += HHashToXml( hKey ) //aVals[ x ] )
                  cXml  += "</" + aKeys[ x ] + ">" + CRLF
               endif
            else
               if !Empty( At( "@", aKeys[ x ] ) )
               //if HAttributes( aKeys, aVals, x )
                  //cXml  += "<" + aKeys[ x ] + ">"
                  //x++
                  //cXml  += HHashToXml( aVals[ x ] )
                  //cXml  += "<" + aKeys[ x ] + ">" + AllTrim( cValToStr( aVals[ x ] ) ) + "</" + aKeys[ x - 1 ] + ">" + CRLF               
               else
                  //if x > 1
                  //   if !Empty( At( "@", aKeys[ x - 1 ] ) )
                  //      cXml  += "</" + aKeys[ x - 2 ] + ">" + CRLF
                  //   else
                  //      cXml  += "</" + aKeys[ x - 1 ] + ">" + CRLF
                  //   endif
                  //endif
                  //cXml  += "<" + aKeys[ x ] + ">" + AllTrim( cValToStr( aVals[ x ] ) ) //+ "</" + aKeys[ x ] + ">" + CRLF
                  if !Empty( At( Chr( 10 ), cValToStr( aVals[ x ] ) ) ) .or. !Empty( At( Chr( 13 ), cValToStr( aVals[ x ] ) ) )
                     cTmp  := "<" + aKeys[ x ] + ">" + StrTran( AllTrim( cValToStr( hKey ) ), CRLF, "" ) + "</" + aKeys[ x ] + ">"
                     cTmp  := StrTran( cTmp, Chr( 10 ), "" )
                     cTmp  := StrTran( cTmp, Chr( 13 ), "" )
                     cXml  += cTmp + CRLF
                  else
                     cXml  += "<" + aKeys[ x ] + ">" + AllTrim( cValToStr( hKey ) ) + "</" + aKeys[ x ] + ">" + CRLF
                  endif
               endif
            endif
         endif
      Next x
   Next y

Return cXml

//----------------------------------------------------------------------------//
// Detect if key and value pair is Attribute
//----------------------------------------------------------------------------//

Static Function HAttributes( aKeys, aVals, x )

   Local nPos := x + 1
   Local lSw  := .F.
   if Len( aKeys ) > nPos
      lSw     := !Empty( At( "@", aKeys[ nPos ] ) )
      //if lSw
      //   ? aKeys[ nPos ]
      //endif
   endif

Return lSw

//----------------------------------------------------------------------------//
// Convert cFile.Json or cJson string to XML 
//----------------------------------------------------------------------------//

METHOD JsonToXml( cFileJson, cJson, cFileXml ) CLASS TXmlToHash

   local nLen        := 0
   local cXml        := ""
   DEFAULT cJson     := ""
   DEFAULT cFileJson := ""
   DEFAULT cFileXml  := ""
   if !Empty( cFileJson ) .and. File( cFileJson )
      cJson   := hb_MemoRead( cFileJson )
   endif
   if !Empty( cJson )
      nLen    := hb_JsonDecode( cJson, @::hHash )
      if nLen > 0 .and. !Empty( ::hHash )
      //
         cXml := ::HashToXml( ::hHash, cFileXml )
      //
      endif
   endif

Return cXml

//----------------------------------------------------------------------------//
// Convert Xml string to Json string and create file.Json
//----------------------------------------------------------------------------//

METHOD XmlToJson( cFileJson, lWrite ) CLASS TXmlToHash

   local cJson       := ""
   DEFAULT cFileJson := "xmltojson.json"
   DEFAULT lWrite    := .T.
   if !Empty( cFileJson )
      if !Empty( ::hHash )
         cJson       := hb_JsonEncode( ::hHash, FW_SetJsonHuman() )  //.T. )
         if File( cFileJSON )
            FErase( cFileJSON )
            // Check if OK
         endif
         if lWrite
            MemoWrit( cFileJson, cJson )   // , lEof
         endif
      endif
   endif

Return cJson

//----------------------------------------------------------------------------//
// Convert XML object, in hash ( ::hHash )
//----------------------------------------------------------------------------//

METHOD XmlToHash( pRoot, cElement ) CLASS TXmlToHash

   Local pNode
   Local hNext
   hb_default( @cElement , "" )

   if empty( cElement )
      pNode     := pRoot
   else   
      pNode     := MxmlFindElement( pRoot, pRoot, cElement, NIL, NIL, MXML_DESCEND )
   endif
      
   if !Empty( pNode )
      hNext     := MxmlWalkNext( pNode, pNode, MXML_DESCEND )
      ::hHash   := ::NodeToHash( hNext )
   endif

Return ::hHash

//---------------------------------------------------------------------------//
//
//----------------------------------------------------------------------------//

METHOD NodeToHash( oNode, hHash ) CLASS TXmlToHash

   local hNext
   local hHashChild  := { => }
   local node2
   local hChild      := { => }
   local cKey
   local nNode       := 0
   local cNode       := ""
   hb_default( @hHash  , { => } )

   While oNode != nil

      if MxmlGetType( oNode ) == MXML_ELEMENT
         if hb_HHaskey( hHash, MxmlGetElement( oNode ) )
            if Valtype( hHash[ MxmlGetElement( oNode ) ] ) != "A"
               cNode := ""
               if Empty( hChild )
                  hChild[ MxmlGetElement( oNode ) ] := {}
                  AAdd( hChild[ MxmlGetElement( oNode ) ] , hHash[ MxmlGetElement( oNode ) ] )
                  AAdd( hChild[ MxmlGetElement( oNode ) ] , MxmlGetOpaque( oNode ) )
               else
                  AAdd( hChild[ MxmlGetElement( oNode ) ], MxmlGetOpaque( oNode ) )
               endif   
               hHash[ MxmlGetElement( oNode ) ] := MxmlGetOpaque( oNode )
            else
               if !::lRepeat
                  cNode := MxmlGetElement( oNode ) + "_" + AllTrim( Str( ++nNode ) )
               else
                  cNode := ""
               endif
            endif   
         else
            if Left( AllTrim( MxmlGetElement( oNode ) ), 3 ) != "!--"  // !-- Esto es un comentario
               if Upper( Left( AllTrim( MxmlGetOpaque( oNode ) ), 8 ) ) == "![CDATA["
                  hHash[ MxmlGetElement( oNode ) ] := StrTran( MxmlGetOpaque( oNode ), "![CDATA[", "" )
                  //hHash[ MxmlGetElement( oNode ) ] := MxmlGetCDATA( oNode )
               else
                  if !Empty( MxmlGetOpaque( oNode ) )
                     cNode  := ""
                     hHash[ MxmlGetElement( oNode ) ] := MxmlGetOpaque( oNode )
                  else
                     // Aqui
                     if !::lRepeat
                        cNode := MxmlGetElement( oNode ) + "_" + AllTrim( Str( ++nNode ) )
                        hHash[ cNode ] := MxmlGetOpaque( oNode )
                     else
                        cNode := ""
                        hHash[ MxmlGetElement( oNode ) ] := MxmlGetOpaque( oNode )
                     endif
                  endif
               endif
            endif
         endif

         if Empty( MxmlGetOpaque( oNode ) )
            hNext := MxmlWalkNext( oNode, oNode, MXML_DESCEND )
            if hNext != NIL
               hHashChild := ::NodeToHash( hNext, )
               if hHashChild != NIL .and. !empty( hHashChild ) 
                  if Empty( hHash[ if( Empty( cNode ), MxmlGetElement( oNode ), cNode ) ] ) 
                     hHash[ if( Empty( cNode ), MxmlGetElement( oNode ), cNode ) ] := {}
                  endif
                  if hb_MxmlGetAttrsCount( oNode ) > 0
                     hHashChild[ if( Empty( cNode ), MxmlGetElement( oNode ), cNode ) + "@attr" ] := hb_MxmlGetAttrs( oNode )
                  endif   
                  AAdd( hHash[ if( Empty( cNode ), MxmlGetElement( oNode ), cNode ) ], hHashChild )
               endif 
            else
               if hb_MxmlGetAttrsCount( oNode ) > 0
                  if Empty( hHash[ if( Empty( cNode ), MxmlGetElement( oNode ), cNode ) ] ) 
                     hHash[ if( Empty( cNode ), MxmlGetElement( oNode ), cNode ) ] := {}
                  endif
                  AAdd( hHash[ if( Empty( cNode ), MxmlGetElement( oNode ), cNode ) ], hb_MxmlGetAttrs( oNode ) )
               endif
            endif
         else
            if hb_MxmlGetAttrsCount( oNode ) > 0
               hHash[ if( Empty( cNode ), MxmlGetElement( oNode ), cNode ) + "@attr" ] := hb_MxmlGetAttrs( oNode )
            endif
         endif
      endif
       
      oNode := MxmlGetNextSibling( oNode ) 
                     
   End While

   if !Empty( hChild )
      cKey := hb_HKeyAt( hChild, 1 )
      hHash[ cKey ] := hChild[ cKey ]
   endif           

return hHash    

//----------------------------------------------------------------------------//
// Return all values 
//----------------------------------------------------------------------------//

METHOD AllValues( oXml ) CLASS TXmlToHash

   local cString  := ""
   local aTmp     := {}
   local hNext
   hb_default( @oXml  , ::oRoot )
   hNext          := oXml

   Do While hNext != Nil
      if MxmlGetType( hNext ) = MXML_ELEMENT
         if Left( MxmlGetElement( hNext ), 3 ) != "!--" .and. ;
            Left( Lower( MxmlGetElement( hNext ) ), 12 ) != "?xml version"
            cString += MxmlGetElement( hNext ) + ' = '
            if hb_MxmlGetAttrsCount( hNext ) > 0
               ::GetAllAttributes( hNext )
            endif
         endif
      endif
      if MxmlGetType( hNext ) = MXML_OPAQUE .and. ! EMPTY ( MxmlGetOpaque( hNext ) )
         if Upper( Left( AllTrim( MxmlGetOpaque( hNext ) ), 8 ) ) == "![CDATA["
            cString += StrTran( StrTran( AllTrim( MxmlGetOpaque( hNext ) ), "![CDATA[", "" ), CRLF, "" ) + CRLF
         else
            cString += StrTran( AllTrim( MxmlGetOpaque( hNext ) ), CRLF, "" ) + CRLF
         endif
      endif
      hNext := MxmlWalkNext( hNext, oXml, MXML_DESCEND )
   Enddo
   ::cXmlString := MxmlSaveAllocString( oXml, MXML_OPAQUE_CALLBACK )
   ::cValString := cString
   aTmp         := hb_ATokens( cString, CRLF )
   AEVal( aTmp, { | a | AAdd( ::aPairsVals, hb_ATokens( a, "=" ) ) } )

return cString

//----------------------------------------------------------------------------//
//
//----------------------------------------------------------------------------//

METHOD GetAllAttributes( hElem, lHash ) CLASS TXmlToHash

   local nAttribs  := 0
   local hAttribs
   local cReturn   := ""
   hb_default( @lHash   , .T. )

   if !Empty( hElem )
      nAttribs := hb_MxmlGetAttrsCount( hElem )
      hAttribs := hb_MxmlGetAttrs( hElem )
   endif

Return if( lHash, hAttribs, cReturn )

//----------------------------------------------------------------------------//
//
//----------------------------------------------------------------------------//

Static Function uType_CallBack()
Return MXML_OPAQUE_CALLBACK    //MXML_OPAQUE

//----------------------------------------------------------------------------//
//
//----------------------------------------------------------------------------//

Static Function MxmlError( cErrorMsg )

   lMxml_Error  := !Empty( cErrorMsg )
   cMxml_Error  := cErrorMsg

Return cMxml_Error

//----------------------------------------------------------------------------//
//
//----------------------------------------------------------------------------//
