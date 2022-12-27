// TODO: Control de errores en deleteresource()
// TODO: Control de errores en setproduct()
// TODO: Pendiente SetProduct()

#include 'fivewin.ch'
#include "hbcurl.ch"
#include "hbxml.ch"

#DEFINE URL_PRODUCTS        'products/'
#DEFINE URL_CATEGORIES      'categories/'
#DEFINE URL_CONFIGURATIONS  'configurations/'
#DEFINE URL_IMAGES          'images/'
#DEFINE GET                 'GET'
#DEFINE DELETE              'DELETE'
#DEFINE POST                'POST'
#DEFINE PUT                 'PUT'
#DEFINE OUTPUTFORMAT        '&output_format=JSON'
#DEFINE BLANKSCHEMA         '&schema=blank'
#DEFINE SYNOPSISCHEMA       '&schema=synopsis'
#DEFINE DIRSCHEMAS          'schemas\'

CLASS TPrestashop 

    PROTECTED:
        DATA cKey           AS CHARACTER Init ''
        DATA cUrlApi        AS CHARACTER Init ''
        DATA hWeb
        DATA hConfiguration AS HASH Init {=>}
        DATA cErrors        AS CHARACTER Init ''

        METHOD cUrl( cUrlResource, cRequest, cOptions, cPostField, cOutputFormat)
        METHOD cUrlDownloadFile( cUrlFile )
        METHOD IniciaWs()
        METHOD GetResourceJson( cUrl, cResource, cOptions )
        METHOD GetResourceXml( cUrl, cOptions )
        METHOD DeleteResource( cUrl, cResource )
        METHOD GetBlankResource( cUrl, cResource )
        method GetSchemaResource( cUrl, cResource )
        METHOD GetConfiguration( nId )
        METHOD MountDisplay( uDisplay )
        METHOD MountFilter( cFilter )
        METHOD MountSort( cSort )
        METHOD MountLimit( cLimit )
        METHOD XmlToString( oXml )
        METHOD GetProductImageAvailableList( nId )
        METHOD GetSchemaReadOnly( cResource )
        METHOD AddImageProduct ( nProductId, cImage )

        METHOD SaveSchema( cResource )
        METHOD CheckDir( cDir )

        METHOD InitErrors()
        METHOD SetErrors()

    EXPORTED:
        METHOD New( cUrlApi ) CONSTRUCTOR
        METHOD End()

        METHOD Initialize()

        METHOD GetResources()
        METHOD GetConfigurations()

        METHOD AddProduct( hProduct )
        METHOD GetProducts( uDisplay, cFilter, cSort, cLimit )
        METHOD GetProduct( nId )
        METHOD GetProductImage( nId )
        METHOD DeleteProduct( nId )
        METHOD SetProduct( nId, hProduct )
        METHOD AddImagesProduct( nProductId, aImages )
        
        METHOD AddCategory( hCategory )
        METHOD GetCategories( uDisplay, cFilter, cSort, cLimit)
        METHOD GetCategory( nId )
        METHOD GetProductImage( nId )
        
        METHOD GetErrors()
        
END CLASS

METHOD New( cKey, cUrlApi ) CLASS TPrestashop
    If cKey <> Nil
        ::cKey := cKey
    Endif
    If cUrlApi <> Nil
        ::cUrlApi := cUrlApi
    Endif

    ::IniciaWs()

Return ( Self )

METHOD End() CLASS TPrestashop
Return ( Nil )

METHOD Initialize() CLASS TPrestashop
    if ::CheckDir( '.\' + DIRSCHEMAS )
        ::SaveSchema( URL_PRODUCTS, 'product' )
    Endif
Return ( Nil )

METHOD SaveSchema( cUrl, cResource )
Local xSchema := ''
Local oRoot := Nil
Local jSchema:= { => }

    xSchema := ::GetSchemaResource( cUrl, cResource )
    oRoot   := TXmlToHash():New( , xSchema, 'product', .t.)
    jSchema := oRoot:XmlToJson()
    hb_MemoWrit( '.\' + DIRSCHEMAS + cResource + '.json', jSchema )

Return ( Nil )

METHOD CheckDir( cDir ) CLASS TPrestashop
Local lOk:=.F.    
    if !( lOk := hb_DirExists( cDir ) )
        lOk := hb_DirCreate( cDir ) == 0
    endif
Return ( lOk )

METHOD DelProduct( nId ) CLASS TPrestashop

    ::DelResource()

Return ( Nil )

METHOD GetProductImage( nId ) CLASS TPrestashop
Local aImages := Array( 0 )    
Local aImagesAvailable := Array( 0 )
Local aImage :={ => }

    aImagesAvailable := ::GetProductImageAvailableList( nId )

    for each aImage in aImagesAvailable
        fImage := ::cUrlDownloadFile( ::cUrlApi + URL_IMAGES + URL_PRODUCTS + hb_ntos( nId )+ '/' + Alltrim( aImage[ 'id' ] ), 'product' + alltrim( aImage[ 'id' ] ) + '.jpg' )
        aAdD( aImages , fImage )
    next
    
Return ( aImages )

METHOD cUrlDownloadFile( cUrlFile, cFile ) CLASS TPrestashop
Local File := ''    

    ::InitErrors()

    curl_easy_reset ( ::hWeb )
    curl_easy_setopt( ::hWeb, HB_CURLOPT_URL,               cUrlFile)
    curl_easy_setopt( ::hWeb, HB_CURLOPT_DL_FILE_SETUP, 	cFile )

    If curl_easy_perform( ::hWeb ) == 0
        hb_memowrit( cFile, curl_easy_dl_buff_get( ::hWeb ) )
    Endif
    
Return ( File )

METHOD GetProductImageAvailableList( nId ) CLASS TPrestashop
Local aImagesAvailableList := Array( 0 )    
    hProduct := ::GetProduct( nId )
    if hb_HHasKey( hProduct, 'associations' ) .And.;
       hb_HHasKey( hProduct[ 'associations' ], 'images' )
       aImagesAvailableList := hProduct[ 'associations' ][ 'images' ]
    Endif
Return ( aImagesAvailableList )

METHOD AddProduct( hProduct ) CLASS TPrestashop
Local nId := 0
Local hBlankProduct := ::GetBlankResource( URL_PRODUCTS, 'product' )
Local nPosition := 0
Local cKey := ''

    oXml := TXMLDocument():New( hBlankProduct )
    For nPosition := 1 To Len( hProduct )
        cKey := hb_HKeyAt( hProduct, nPosition )
        AsignacData( oXml, cKey, hProduct[ cKey ] )
    Next
    xXml:= ::XmlToString( oXml )  
    jResponse := ::cUrl( URL_PRODUCTS, POST, , xXml )
    hResponse := hb_jsonDecode( jResponse )
    If hb_HHasKey( hResponse, 'product' ) .And. ;
       hb_HHasKey( hResponse[ 'product' ], 'id' )
        nId := Val( hResponse[ 'product' ][ 'id' ] )
    Else
        ::SetErrors( hResponse )
        nId := 0
    Endif
Return ( nId )

METHOD SetProduct( nId, hProduct ) CLASS TPrestashop
Local hProductResource:= ::GetResourceXml( URL_PRODUCTS + hb_ntos( nId ) )
Local aReadOnly := ::GetSchemaReadOnly ( 'product' )
Local cReadOnly := ''

    oXml := TXMLDocument():New( hProductResource )
    hb_MemoWrit('productantes.xml',::XmlToString( oXml ) )
    For nPosition := 1 To Len( hProduct )
        cKey := hb_HKeyAt( hProduct, nPosition )
        AsignacData( oXml, cKey, hProduct[ cKey ] )
    Next

    for each cReadOnly in aReadOnly
        oNode := oXml:FindFirst( cReadOnly ) 
        oNode:Unlink()
    next

    xXml := ::XmlToString( oXml ) 
    hb_MemoWrit('product despues.xml',xXml)
    jResponse := ::cUrl( URL_PRODUCTS + hb_ntos( nId ), PUT, , xXml)
    hResponse := hb_jsonDecode( jResponse )
    If hb_HHasKey( hResponse, 'product' ) .And. ;
       hb_HHasKey( hResponse[ 'product' ], 'id' )
        nId := Val( hResponse[ 'product' ][ 'id' ] )
    Else
        ::SetErrors( hResponse )
        nId := 0
    Endif
Return ( nId )

METHOD AddImagesProduct( nProductId, aImages ) CLASS TPrestashop
Local aId := Array( 0 )
Local cImage := ''

    if ValType( aImages ) <> 'A'
        aImages := { aImages }
    Endif

    for each cImage in aImages
        nId := ::AddImageProduct( nProductId, cImage )
        aAdD( aId, { nId, cImage } )
    next

Return ( aId )

METHOD AddImageProduct ( nProductId, cImage ) CLASS TPrestashop
Loca nId := 0

    fErase('tempfile.tmp')
    ccurl:='curl.exe -v -u '+;
           cKey + ':' + ::cKey + ' '+;
           '-F ' + Chr( 34 ) + 'image=@' + cImage + Chr( 34 ) + ' ' +;
           '--output tempfile.tmp ' +;
           ' -k ' +;
           ::cUrlApi + '/images/products/' + hb_ntos( nProductId ) + OUTPUTFORMAT
    WaitRun ( ccurl, 3 )  
    hResponse := hb_jsondecode( hb_MemoRead( 'tempfile.tmp' ) )
    fErase('tempfile.tmp')

    if hb_HHasKey( hResponse , 'image' ) .And.;
       hb_HHasKey( hResponse[ 'image' ], 'id' )
       nId := hResponse[ 'image' ][ 'id' ]
    Endif

Return ( nId )

METHOD GetSchemaReadOnly( cResource )
Local aReadOnly := Array( 0 )
Local cFile := '.\' + DIRSCHEMAS + cResource + '.json'
Local jSchema := ''
Local nPosition := 0
Local hValue := { => }

If File( cFile )
        jSchema := hb_jsondecode( hb_memoread( cFile ) )

        For nPosition := 1 To Len( jSchema )
            cKey := hb_HKeyAt( jSchema, nPosition )
            If ValType ( jSchema[ cKey ] ) == 'A'
                for each hValue in jSchema[ cKey ]
                    If ( hb_hPos( hValue, 'read_only' ) <> 0 .And. hValue[ 'read_only' ] == 'true' ) .Or. ;
                       ( hb_hPos( hValue, 'readOnly' ) <> 0 .And. hValue[ 'readOnly' ] == 'true' )
                        aAdD( aReadOnly ,cKey )
                    Endif
                next
            Endif
        next
    Endif
Return ( aReadOnly )

METHOD AddCategory( hCategory ) CLASS TPrestashop
Local nId := 0
Local hBlankCategory := ::GetBlankResource( URL_CATEGORIES )
Local nPosition := 0
Local cKey := ''

    oXml := TXMLDocument():New( hBlankCategory )
    For nPosition := 1 To Len( hCategory )
        cKey := hb_HKeyAt( hCategory, nPosition )
        AsignacData( oXml, cKey, hCategory[ cKey ] )
    Next
    xXml := ::XmlToString( oXml ) 
    jResponse := ::cUrl( URL_CATEGORIES, POST, , xXml )
    hResponse := hb_jsonDecode( jResponse )
    If hb_HHasKey( hResponse, 'category' ) .And. ;
       hb_HHasKey( hResponse[ 'category' ], 'id' )
        nId := Val( hResponse[ 'category' ][ 'id' ] )
    Else
        ::SetErrors( hResponse )
        nId := 0
    Endif
Return ( nId )

METHOD GetBlankResource( cUrl )
Return ::GetResourceXml( cUrl, BLANKSCHEMA )

METHOD GetSchemaResource( cUrl )
Return ::GetResourceXml( cUrl, SYNOPSISCHEMA )

METHOD GetConfigurations() CLASS TPrestashop
Local aConfigurations:=::GetResourceJson(URL_CONFIGURATIONS,'configurations')
Local hConfiguracion:={=>}
Local hTmp:={=>}

    for each hConfiguracion in aConfigurations
        hTmp:=::GetConfiguration( hConfiguracion['id'] )
        ::hConfiguration[ hTmp['name'] ] := hTmp['value']
    next

Return (::hConfiguration)

METHOD GetConfiguration(nId) CLASS TPrestashop
Return ::GetResourceJson( URL_CONFIGURATIONS + '/' + hb_ntos(nId) , 'configuration' )

METHOD GetCategories(uDisplay,cFilter,cSort,cLimit) CLASS TPrestashop
Return ::GetResourceJson(;
                     URL_CATEGORIES,;
                     'categories',;
                     ::MountDisplay(uDisplay)+;
                     ::MountFilter(cFilter)+;
                     ::MountSort(cSort)+;
                     ::MountLimit(cLimit);
                     )

METHOD GetCategory(nId) CLASS TPrestashop
Return ::GetResourceJson( URL_CATEGORIES + '/' + hb_ntos(nId) , 'category' )

METHOD GetProducts(uDisplay,cFilter,cSort,cLimit) CLASS TPrestashop
    
Return ::GetResourceJson( ;
                        URL_PRODUCTS,;
                        'products',;
                        ::MountDisplay(uDisplay)+;
                        ::MountFilter(cFilter)+;
                        ::MountSort(cSort)+;
                        ::MountLimit(cLimit);
                    )

METHOD GetProduct(nId) CLASS TPrestashop
Return ::GetResourceJson( URL_PRODUCTS + '/' + hb_ntos(nId) , 'product' )

METHOD DeleteProduct(nId) CLASS TPrestashop
Return ::DeleteResource( URL_PRODUCTS + hb_ntos(nId) )

METHOD GetResources() CLASS TPrestashop
Return ::GetResourceJson( '/' )


METHOD cUrl(cUrlResource,cRequest,cOptions,cPostField,cOutputFormat) CLASS TPrestashop
Local cDev:=''    
    Default cOptions:=''
    Default cOutputFormat:=OUTPUTFORMAT

    ::InitErrors()

    curl_easy_reset ( ::hWeb )
    curl_easy_setopt( ::hWeb, HB_CURLOPT_URL,           ::cUrlApi+cUrlResource+cOptions+cOutputFormat)
    curl_easy_setopt( ::hWeb, HB_CURLOPT_USERPWD,       ::cKey )
    curl_easy_setopt( ::hWeb, HB_CURLOPT_CUSTOMREQUEST, cRequest ) 
    curl_easy_setopt( ::hWeb, HB_CURLOPT_DL_BUFF_SETUP ) 
    If cPostField<>Nil
        curl_easy_setopt( ::hWeb, HB_CURLOPT_POSTFIELDS, cPostField )
    Endif
    If curl_easy_perform(::hWeb)==0
        cDev:=curl_easy_dl_buff_get( ::hWeb )
    Endif
Return (cDev)

METHOD IniciaWs() CLASS TPrestashop
    curl_global_init()
    ::hWeb := curl_easy_init()
Return ( Nil )

METHOD GetResourceJson(cUrl,cResource,cOptions) CLASS TPrestashop
Local aResource:={=>}
Local jResponse:=''
Local hResponse:={=>}

    If !Empty( jResponse := ::cUrl(cUrl,GET,cOptions) )
        If !Empty(cResource)
            If hb_HHasKey( hResponse := hb_jsonDecode( jResponse ), cResource )
              aResource := hResponse[ cResource ]
            Endif 
        Else
            aResource := hb_jsonDecode( jResponse )
        Endif
    Endif
Return aResource

METHOD GetResourceXml(cUrl,cOptions) CLASS TPrestashop
Local xResponse:=''
    xResponse := ::cUrl(cUrl,GET,cOptions,,'') 
Return xResponse

METHOD DeleteResource(cUrl,cResource) CLASS TPrestashop
Local xResponse:=''
    xResponse := ::cUrl(cUrl,DELETE) 
Return xResponse

METHOD MountDisplay(uDisplay) CLASS TPrestashop
Local cDisplay:=''
    If uDisplay<>Nil
        If ValType(uDisplay)=='A'
            cDisplay:='['
            aEval(uDisplay,{|a|cDisplay+=a+','})
            cDisplay:=Substr(cDisplay,1,Len(cDisplay)-1)
            cDisplay+=']'
        Elseif ValType(uDisplay)=='C'
            cDisplay:=uDisplay
        Endif
        cDisplay:='&display='+Alltrim(cDisplay)
    Endif
Return (cDisplay)

METHOD MountFilter(cFilter) CLASS TPrestashop
    If cFilter==Nil
        cFilter:=''
    Else
        cFilter:='&filter'+Alltrim(cFilter)
    Endif
Return (cFilter)

METHOD MountSort(cSort) CLASS TPrestashop
    If cSort==Nil
        cSort:=''
    Else
        cSort:='&sort=['+Alltrim(cSort)+']'
    Endif
Return (cSort)

METHOD MountLimit(cLimit) CLASS TPrestashop
    If cLimit==Nil
        cLimit:=''
    Else
        cLimit:='&limit='+Alltrim(cLimit)
    Endif
Return (cLimit)

METHOD XmlToString(oXml) CLASS TPrestashop
Local xXml:=''
    xXml:=oXml:ToString()
    xXml:=StrTran(xXml,Chr(10),'')
    xXml:=StrTran(xXml,Chr(13),'') 
Return xXml


METHOD SetErrors(hResponse) CLASS TPrestashop
Local herror:={=>}    
    ::cErrors:=''
    if hb_HHasKey(hResponse,'errors')
        for each herror in hResponse['errors']
            ::cErrors+='code:'+hb_ntos(herror['code'])+' '+Alltrim(herror['message'])+CRLF
        next
    Endif
Return ( Nil )

METHOD InitErrors() CLASS TPrestashop
    ::cErrors:=''
Return ( Nil )

METHOD GetErrors() CLASS TPrestashop
Return (::cErrors)

Static Function AsignacData( oXml, cElement, uData )
Local oNode    
Local oChild

    oNode := oXml:FindFirst( cElement )
    If oNode<>Nil
        if ValType( uData ) == 'H'
            oChild := oNode:oChild
            While oChild:oNext <> Nil
                if Alltrim( uData[ 'propierty' ] ) == Alltrim( oChild:cName ) .And.;
                   Alltrim( oChild:aAttributes[ uData[ 'attribute' ] ] ) == uData[ 'attributevalue' ]
                    oChild:cData := uData[ 'value' ]
                Endif
                oChild := oChild:oNext
            Enddo
        Else
            If oNode:oChild == Nil
                oNode:AddBelow( TxmlNode():New( HBXML_TYPE_CDATA, cElement, , uData ) )
            Else
                oNode:oChild:cData := uData
            Endif
        Endif
    Endif

Return ( Nil )