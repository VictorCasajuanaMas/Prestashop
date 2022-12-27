#include "fivewin.ch"


FUNCTION Main(cParameters)

    aParameters:=hb_ATokens(cParameters,',')

    if Len(aParameters)==2
        cKey:=Alltrim(aParameters[1])
        cUrl:=Alltrim(aParameters[2])

        oPrestashop:=TPrestashop():New(cKey,cUrl)

        oPrestashop:Initialize()

        oPrestashop:GetProductImage(1)

        nId:=oPrestashop:AddCategory({;
                                        'name'              =>{;
                                                                'propierty'=>       'language',;
                                                                'attribute'=>       'id',;
                                                                'attributevalue'=>  '1',;
                                                                'value'=>           'Categoría nueva por TPrestashop()';
                                                                },;
                                        'link_rewrite'      =>{;
                                                                'propierty'=>       'language',;
                                                                'attribute'=>       'id',;
                                                                'attributevalue'=>  '1',;
                                                                'value'=>           'CATEGORIA_NUEVA';
                                                                },;
                                        'active'             =>'1',;
                                        'id_parent'          =>'2',;
                                        'level_depth'        =>'2',;
                                        'id_shop_default'    =>'1';
                                    })
        If nId>0
            MsgInfo('Se ha creado la categoria con id:'+hb_ntos(nId))
        Else
            MsgInfo(oPrestashop:GetErrors(),'Error creando categoría')
        Endif                                    
    
        hResources:=oPrestashop:GetResources()         
        xBrowse(hResources,'Todos los recursos disponibles')

        hCategories:=oPrestashop:GetCategories()        
        xBrowse(hCategories,'Todas las categorías disponibles')

        hCategories:=oPrestashop:GetCategories({'id','name'})
        xBrowse(hCategories,'Todas las categorías con nombre e id')

        hProducts:=oPrestashop:GetProducts()
        xBrowse(hProducts,'Todos los productos disponibles')

        hProducts:=oPrestashop:GetProducts('full')
        xBrowse(hProducts,'Todos los productos disponibles con la información de cada producto')

        hProducts:=oPrestashop:GetProducts({'id','name','price'})
        xBrowse(hProducts,'Todos los productos solo con los campos id, name y price')

        hProducts:=oPrestashop:GetProducts({'id','name','price'},'[id]=[1,10]')
        xBrowse(hProducts,'Productos cuyas id están entre 1 y 10 con  los campos id, name y price ')

        hProducts:=oPrestashop:GetProducts({'id','name','price'},'[id]=[1,10]','price_asc,id_desc')
        xBrowse(hProducts,'Productos cuyas id están entre 1 y 10 con los campos id, name y price, ordenado por precio descendentemente y a precios iguales por id descendente')

        hProducts:=oPrestashop:GetProducts({'id','name','price'},'[id]=[1,10]','price_asc,id_desc','5')
        xBrowse(hProducts,'5 primeros productos cuyas id están entre 1 y 10 con los campos id, name y price, ordenado por precio descendentemente y a precios iguales por id descendente')

        hProducts:=oPrestashop:GetProducts({'id','name','price'},'[id]=[1,10]','price_asc,id_desc','8,5')
        xBrowse(hProducts,'5 primeros productos empezando por el 8º cuyas id están entre 1 y 10 con los campos id, name y price, ordenado por precio descendentemente y a precios iguales por id descendente')

        hProduct:=oPrestashop:GetProduct(30)
        xBrowse(hProduct,'Producto 30')

        nId:=oPrestashop:AddProduct({;
                                        'name'              =>{;
                                                                'propierty'=>       'language',;
                                                                'attribute'=>       'id',;
                                                                'attributevalue'=>  '1',;
                                                                'value'=>           'Artículo nuevo por TPrestashop()';
                                                                },;
                                        'description'       =>{;
                                                                'propierty'=>       'language',;
                                                                'attribute'=>       'id',;
                                                                'attributevalue'=>  '1',;
                                                                'value'=>           'Descriopción larga del artículo nuevo por TPrestashop';
                                                                },;
                                        'id_shop_default'    =>'1',;
                                        'is_virtual'         =>'0',;
                                        'state'              =>'1',;
                                        'online_only'        =>'0',;
                                        'low_stock_alert'    =>'0',;
                                        'price'              =>'123',;
                                        'wholesale_price'    =>'123',;
                                        'active'             =>'1',;
                                        'available_for_order'=>'1',;
                                        'show_price'         =>'1',;
                                        'indexed'            =>'1';
                                    })
        If nId>0
            MsgInfo('Se ha creado el producto con id:'+hb_ntos(nId))

            If Empty(oPrestashop:DeleteProduct(nId))
                MsgInfo('producto '+hb_ntos(nId)+' eliminado')
            Else
                MsgInfo(oPrestashop:GetErrors(),'Error eliminando producto')
            Endif
        Else
            MsgInfo(oPrestashop:GetErrors(),'Error creando producto')
        Endif
        
        nId:=oPrestashop:SetProduct(102,{;
                                            'name'              =>{;
                                                                'propierty'=>       'language',;
                                                                'attribute'=>       'id',;
                                                                'attributevalue'=>  '1',;
                                                                'value'=>           'Artículo modificado por TPrestashop() a las '+Time();
                                                                },;
                                            'price'     =>'111',;
                                            'ean13'     =>'5902701701475'})
        If nId<>0
            MsgInfo( 'Producto ' + hb_ntos( nId ) + ' modificado correctamente ')
        Else
            MsgInfo( oPrestashop:GetErrors() , 'Error modificando producto ')
        Endif                                            

        aId:=oPrestashop:AddImagesProduct(102,'world.jpg')
        If aScan(aId,{|aId|aId[1]==0})==0
            xBrowse(aId,'Imágenes subidas con sus respectiva id')
        Else
            MsgInfo( oPrestashop:GetErrors() , 'Error subiendo imagen ')
        Endif
        
        hConfiguracion:={=>}
        MsgRun('Proceso','Recibiendo Configuracion',{||hConfiguracion:=oPrestashop:GetConfigurations()})
        xBrowse(hConfiguracion,'Toma toda la configuración de prestashop')

    Endif
  
RETU NIL