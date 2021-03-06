#INCLUDE "TOTVS.CH"

#DEFINE SINGLE "01"
#DEFINE ALL    "02"
#DEFINE INSERT "03"
#DEFINE DELETE "04"
#DEFINE UPDATE "05"
#DEFINE BUSCA  "07"

/*/{Protheus.doc} CenRequest
    Classe abstrata que controla o corpo dos endpoints dos servicos rest do autorizador
    @type  Class
    @author victor.silva
    @since 20180427
/*/
Class CenRequest
	
    Data oRest
    Data cSvcName
    Data cResponse
    Data cPropLote
    Data cFaultDesc
    Data cFaultDetail
    Data lSuccess
    Data nStatus
    Data nFault
    Data oReqBody
    Data oRespBody
    Data oRespControl
    Data oCollection
    Data jRequest
    Data oValidador

    Method New(oRest, cSvcName) Constructor

    Method destroy()
    Method checkAuth()
    Method applyFields()
    Method applyPageSize()
    Method checkBody()
    Method getSuccess()
    Method initRequest()
    Method endRequest()
    Method serializeFault()
    Method checkAgreement()
    Method procGet(nType)
    Method procDelete()
    Method procPost(cJson,oCmd)
    Method procLotePost(oCmd)
    Method procPut(oCmd)
    Method buildBody(oEntity)
    
EndClass

Method New(oRest, cSvcName) Class CenRequest
    self:oRest        := oRest
    self:cSvcName     := cSvcName
    self:lSuccess     := .T.
    self:nStatus      := 200
    self:oReqBody     := JsonObject():New()
    self:oRespBody    := JsonObject():New()
    self:jRequest     := JsonObject():New()
    self:oRespControl := CenJsonControl():New()
    self:nFault       := 0
    self:cFaultDesc   := ''
    self:cResponse    := ''
    self:cFaultDetail := ''
Return self

Method destroy() Class CenRequest
    
    FreeObj(self:oReqBody)
    self:oReqBody := nil
    
    FreeObj(self:oRespBody)
    self:oRespBody := nil
    
    FreeObj(self:oRespControl)
    self:oRespControl := nil
    
    FreeObj(self:oCollection)
    self:oCollection := nil

    FreeObj(self:jRequest)
    self:jRequest := nil
    
    FreeObj(self:oValidador)
    self:oValidador := nil
    
Return

/*/{Protheus.doc} checkAuth
Valida as informacoes de autenticacao do usuario com as informacoes do header da requisicao
@author  victor.silva
@since   20180518
/*/
Method checkAuth() Class CenRequest
    // TODO - IMPLEMENTAR LEITURA DO HEADER COM A AUTENTICACAO DO USUARIO
    // self:oRest:getHeader()
    // VarInfo("REST",ClassMethArr(self:oRest,.T.))
Return self:lSuccess

Method applyFields() Class CenRequest
    self:oRespControl:prepFields(self:oRest:fields)
Return

/*/{Protheus.doc} applyPageSize
Aplica o tamanho da pagina para paginas do tipo colecao
@author  victor.silva
@since   20180523
/*/
Method applyPageSize() Class CenRequest

    Default self:oRest:page := "1"
    Default self:oRest:pageSize := "20"
    
    self:oCollection:applyPageSize(self:oRest:page,self:oRest:pageSize)
    self:oRespBody["hasNext"] := .F.
    self:oRespBody["items"] := {}

Return self:lSuccess

/*/{Protheus.doc} checkBody
Realiza o parser do JSon enviado pelo client
@author  victor.silva
@since   20180518
/*/
Method checkBody() Class CenRequest
    Local cParseError := ""

    // TODO - SYSLOG RFC-5424
    cParseError := self:jRequest:fromJson(DecodeUTF8(self:oRest:GetContent(), "cp1252"))

    if empty(cParseError)
         self:lSuccess  := .T.
    else
        self:nFault     := 400
        self:cFaultDesc   := "N�o foi poss�vel fazer o parse da mensagem."
        self:cFaultDetail := cParseError
        self:lSuccess   := .F.
    endif

Return self:lSuccess

Method getSuccess() Class CenRequest
Return .T.

/*/{Protheus.doc} endRequest
Inicializa a solicitacao
@author  victor.silva
@since   20180518
/*/
Method initRequest() Class CenRequest
    // TODO - SYSLOG RFC-5424
Return

/*/{Protheus.doc} endRequest
Finaliza a solicitacao e coloca a resposta e status na requisicao
@author  victor.silva
@since   20180518
/*/
Method endRequest() Class CenRequest
    Local cResponse := ""
    if self:lSuccess
        self:oRest:setStatus(self:nStatus)
        cResponse := EncodeUTF8(self:cResponse)
        self:oRest:setResponse(cResponse)
    else
        self:oRest:setStatus(self:nStatus)
        cResponse := EncodeUTF8(self:serializeFault())
        self:oRest:setResponse(cResponse)
        // TODO - AutSysLog: dinamizar o tenantId quando prepararmos a aplica��o para trabalhar com tenant
        //AutSysLog(ProcName(), RESTAPI, INFORMATIONAL, 1, self:cMsgId, "[tenantId=1]", {"Finalizando requisi��o com erro: " + cResponse })
    endif
Return

/*/{Protheus.doc} serializeFault
Serializa retorno de falha do WSREST
@author  victor.silva
@since   20180704
/*/
Method serializeFault() Class CenRequest

    Local oJson := JsonObject():New()

    oJson["code"] := self:nFault
    oJson["message"] := self:cFaultDesc
    oJson["detailedMessage"] := self:cFaultDetail
    oJson["helpUrl"] := ""
    oJson["details"] := {}
    aAdd(oJson["details"], JsonObject():New())
    oJson["details"][1]["code"] := ""
    oJson["details"][1]["message"] := ""
    oJson["details"][1]["detailedMessage"] := ""
    oJson["details"][1]["helpUrl"] := ""

Return oJson:toJson()

Method checkAgreement() class CenRequest
Return .T.

Method procGet(nType) Class CenRequest
    Local nRegistro     := 1
    Local oEntity     := nil

    If self:lSuccess
        if self:oCollection:found()
            If nType == ALL
                while self:oCollection:hasNext() .And. nRegistro <= Val(self:oCollection:getPageSize())
                    oEntity := self:oCollection:getNext(oEntity)
                    oEntity:setHashFields(self:oRespControl:hmFields)
                    aAdd(self:oRespBody['items'], self:buildBody(oEntity))
                    nRegistro++
                enddo
                self:oRespBody["hasNext"] := self:oCollection:hasNext()
                self:cResponse := self:oRespBody:toJson()
            Else
                oEntity := self:oCollection:getNext(oEntity)
                oEntity:setHashFields(self:oRespControl:hmFields)
                self:jRequest := self:buildBody(oEntity)
                self:cResponse := self:jRequest:toJson()
            Endif
            oEntity:destroy()
        Else
            self:nFault       := 404
            self:nStatus      := 404
            self:cFaultDesc   := "Opera��o n�o pode ser realizada."
            self:cFaultDetail := "Registro n�o encontrado."
        Endif        
    Else
        self:nFault       := 404
        self:nStatus      := 404
        self:cFaultDesc   := "Opera��o n�o pode ser realizada."
        self:cFaultDetail := "Registro n�o encontrado."
    Endif

    FreeObj(oEntity)
    oEntity := Nil

Return self:lSuccess

Method procDelete() Class CenRequest

    If self:lSuccess
        If (self:oCollection:delete())
            self:nStatus := 204
            self:cResponse := ""
        EndIf
    EndIf

Return self:lSuccess

Method procPost() Class CenRequest
    
    Local cJsonResp     := ""
    Local oEntity   := nil
    Local oCmd := CenCmdPostClt():New(self:oCollection)
    
    if self:lSuccess
        self:prepFilter(self:jRequest)
        self:buscar(INSERT)
        If self:lSuccess
            If self:oValidador:validate(self:oCollection) //Validate
                If oCmd:execute()
                    self:nStatus := 201
                    If self:buscar(SINGLE)
                        oEntity := self:oCollection:getNext()
                        self:oRespBody := oEntity:serialize(self:oRespControl)
                        cJsonResp := self:oRespBody:toJson()
                        oEntity:destroy()
                    EndIf
                    self:cResponse := cJsonResp
                Else
                    self:lSuccess     := .F. 
                    self:nFault       := 400
                    self:nStatus      := 400
                    self:cFaultDesc   := "Opera��o n�o pode ser realizada."
                    self:cFaultDetail := "Erro ao realizar insert."
                Endif
            Else
                self:lSuccess     := .F. 
                self:nFault       := 400
                self:nStatus      := 400
                self:cFaultDesc   := "Opera��o n�o pode ser realizada."
                self:cFaultDetail := self:oValidador:getErrMsg()
            EndIf //Fim Validate
        Else
            self:nFault       := 400
            self:nStatus      := 400
            self:cFaultDesc   := "Opera��o n�o pode ser realizada."
            self:cFaultDetail := "Registro j� existe no banco."
        EndIf
    Endif

    FreeObj(oEntity)
    oEntity := Nil

Return self:lSuccess

Method procLotePost(oCmd) Class CenRequest

    Local nMinLimit     := 1
    Local nMaxLimit     := 100
    Local nRegistro     := 1
    Local nCount        := 0
    Local oEntity       := 0
    Local jAlreadyExists:= JsonObject():New()        
    Local jErrors       := JsonObject():New()
    Local jSerialize    := AutJsonControl():New()
    Local jLoteResponse := JsonObject():New()
    Default oCmd := CenCmdPostClt():New(self:oCollection)

    self:oRespBody      := nil
    
    jSerialize:newArray(jLoteResponse, 'included')
    jSerialize:newArray(jLoteResponse, 'notIncluded')

    jSerialize:newArray(jAlreadyExists, self:cPropLote)
    jSerialize:setProp(jAlreadyExists, 'codeError', 400)
    jSerialize:setProp(jAlreadyExists, 'errorMessage', 'Benefici�rio(s) J� existe(m).')

    jSerialize:newArray(jErrors, self:cPropLote)
    jSerialize:setProp(jErrors, 'codeError', 400)
    jSerialize:setProp(jErrors, 'errorMessage', 'Erro ao tentar inserir Benefici�rio(s).')
           
    If self:lSuccess
        If ValType(self:jRequest) == "A"
            nCount := Len(self:jRequest)
            If nCount >= nMinLimit .AND. nCount <= nMaxLimit
                For nRegistro := 1 to nCount
                    self:prepFilter(self:jRequest[nRegistro])
                    self:applyFilter(SINGLE)
                    self:buscar(INSERT)
                    If self:lSuccess
                        If oCmd:execute()
                            If self:buscar(BUSCA)
                                oEntity := self:oCollection:getNext()
                                jSerialize:addObjtoProp(jLoteResponse, 'included', oEntity:serialize(self:oRespControl))
                                oEntity:destroy()
                            EndIf
                        Else
                            jSerialize:addObjtoProp(jErrors, self:cPropLote, self:jRequest[nRegistro])
                        EndIf
                    Else
                        jSerialize:addObjtoProp(jAlreadyExists, self:cPropLote, self:jRequest[nRegistro])
                    EndIf
                    self:oRespControl := Nil
                Next

                If len(jAlreadyExists["beneficiaries"]) >= 1
                    aAdd(jLoteResponse["notIncluded"], jAlreadyExists)    
                EndIf
                If len(jErrors["beneficiaries"]) >= 1
                    aAdd(jLoteResponse["notIncluded"], jErrors)
                EndIf
                
                self:lSuccess  := .T.
                self:nStatus   := 200
                self:cResponse := jLoteResponse:toJson()

            Else 
                self:lSuccess     := .F.
                self:nStatus      := 400
                self:nFault       := 400
                self:cFaultDesc   := "Opera��o n�o pode ser realizada."
                self:cFaultDetail := "Opera��o em lote s� � permitida de " + cValToChar(nMinLimit) + " a " + cValToChar(nMaxLimit) + " registros."
            EndIf
        Else
            self:lSuccess     := .F.
            self:nStatus      := 400
            self:nFault       := 400
            self:cFaultDesc   := "Opera��o n�o pode ser realizada."
            self:cFaultDetail := "Opera��o s� pode ser realizada em lote, informe um array de objetos v�lidos."
        EndIf
    EndIf

    FreeObj(oEntity)
    FreeObj(jLoteResponse)
    FreeObj(jSerialize)
    FreeObj(jAlreadyExists)
    FreeObj(jErrors)
    oEntity := Nil
    jLoteResponse := Nil
    jSerialize := Nil
    jAlreadyExists := Nil
    jErrors := Nil

Return self:lSuccess

Method procPut(oCmd) Class CenRequest
    Local cJson     := ''
    Local oEntity   := nil
    Default oCmd := CenCmdPutClt():New(self:oCollection)
    
    If self:lSuccess
        self:prepFilter()
        self:applyFilter(SINGLE)
        self:buscar(SINGLE)
        If self:lSuccess
            If self:oValidador:validate(self:oCollection) //Validate
                If oCmd:execute()
                    self:nStatus := 200
                    If self:buscar(SINGLE)
                        oEntity := self:oCollection:getNext()
                        self:oRespBody := oEntity:serialize(self:oRespControl)
                        cJson := self:oRespBody:toJson()
                        oEntity:destroy()
                    EndIf
                    self:cResponse := cJson
                Else
                    self:lSuccess     := .F. 
                    self:nFault       := 400
                    self:nStatus      := 400
                    self:cFaultDesc   := "Opera��o n�o pode ser realizada."
                    self:cFaultDetail := "Erro ao realizar update."
                Endif
            EndIf //Fim Validate
        Else
            self:nFault       := 404
            self:nStatus      := 404
            self:cFaultDesc   := "Opera��o n�o pode ser realizada."
            self:cFaultDetail := "Registro n�o encontrado."
        EndIf
    Endif

    FreeObj(oEntity)
    oEntity := Nil
 
Return self:lSuccess

Method procDelete() Class RestRequest

    If self:lSuccess
        If (self:oCollection:delete())
            self:nStatus := 204
            self:cResponse := ""
        EndIf
    EndIf

Return self:lSuccess

Method buildBody(oEntity) Class CenRequest
Return oEntity:serialize(self:oRespControl)