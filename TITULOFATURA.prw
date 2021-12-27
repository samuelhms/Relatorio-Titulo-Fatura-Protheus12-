#INCLUDE "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "Topconn.ch"
#INCLUDE "totvs.ch"
//--------------------------------------------------------------

//--------------------------------------------------------------
User Function TITULOFAT()
	Static oDoc
	Static cDoc := '000000000'
	Static oData

	Static oFilial
	Static nFilial

	Static dDiaini
	Static dDiafim

    Static diniPT
    Static dfimPT

	Static oSay1
	Static oSay2
	Static oSay3
	Static oSay4
	Static oDlg
	Static aFilial := FWAllFilial(,,,.F.)

    Static aDados :={}

	DEFINE MSDIALOG oDlg TITLE "Titulo x Faturamento" FROM 000, 000  TO 600, 600 COLORS 0, 16777215 PIXEL



	@ 015, 025 SAY oSay1 PROMPT "Filial ?" SIZE 026, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 025, 025 MSCOMBOBOX oFilial VAR nFilial ITEMS aFilial SIZE 072, 010 OF oDlg COLORS 0, 16777215 PIXEL

	@ 045, 025 SAY oSay3 PROMPT "Data de Inicio" SIZE 060, 025 OF oDlg COLORS 0, 16777215 PIXEL
	dDiaini := ctod("01/01/21")
	@ 055,025 MSGET oData  VAR dDiaini;
		PICTURE "@D" SIZE 50, 10 OF oDlg PIXEL HASBUTTON

    @ 075, 025 SAY oSay4 PROMPT "Data Fim" SIZE 060, 025 OF oDlg COLORS 0, 16777215 PIXEL
	dDiafim := ctod("31/12/21")
	@ 085,025 MSGET oData  VAR dDiafim;
		PICTURE "@D" SIZE 50, 10 OF oDlg PIXEL HASBUTTON

	@ 105, 025 SAY oSay2 PROMPT "Documento separado por vírgurla" SIZE 099, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 115, 025 MSGET oDoc VAR cDoc SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL PICTURE '@E 999999999'

	@ 250, 135 BUTTON oBtPdf PROMPT "Gerar Relatório" SIZE 078, 022 OF oDlg ACTION validaDados()  PIXEL
	@ 251, 221 BUTTON oBtCancelar PROMPT "Cancelar" SIZE 078, 022 OF oDlg ACTION Close(oDlg) PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

Return

//--------------------------------------------------------------
Static Function validaDados()

	if dDiaini != NIL .and. dDiafim != NIL .and. nFilial != NIL //.and. cDoc != NIL ]

  diniPT := Year2Str(dDiaini)+''+	Month2Str(dDiaini)+''+Day2Str(dDiaini)
  dfimPT := Year2Str(dDiafim)+''+	Month2Str(dDiafim)+''+Day2Str(dDiafim)

		

    fZZReport()
	else
		MsgAlert("Campos não preenchidos")
	endif

Return
//------------------------------------------------------------------------------------------
// GERAR RELATORIO EM PDF 
//------------------------------------------------------------------------------------------
Static function fZZReport() // u_fZZReport()
  
	Local oReport	
  aDados := importRel()

	oReport := ReportDef()
	oReport:PrintDialog()
Return
//------------------------------------------------------------------------------------------
// SQL DADOS ON ARRAY ADADOS{}
//------------------------------------------------------------------------------------------
STATIC Function importRel()
	
	Local cQuery := ""

	cQuery +=" SELECT DISTINCT E2_PREFIXO AS PREF,"
	cQuery +=" E2_NUM AS NUM,"
	cQuery +=" E2_PARCELA AS PARCELA,"
	cQuery +=" E2_TIPO AS TIPO,"
	cQuery +=" E2_FORNECE + ' - ' + E2_LOJA + ' - ' + E2_NOMFOR AS FORNECEDOR,"
	cQuery +=" CAST(E2_EMISSAO AS DATE) AS EMISSAO,"
	cQuery +=" CAST(E2_VENCTO AS DATE) AS VENCIMENTO,"
	cQuery +=" CAST(E2_VALOR AS MONEY) AS VALOR,"

	cQuery +=" E2_FATURA AS FATURA FROM SE2010"

	cQuery +=" WHERE E2_TIPO <> 'FT'"
	cQuery +=" AND E2_FATURA IN ('"+cDoc+"') "
	cQuery +=" AND E2_EMISSAO BETWEEN '"+diniPT+"' AND '"+dfimPT+"'"
	cQuery +=" AND E2_FILIAL = '"+nFilial+"'"
	cQuery +=" AND D_E_L_E_T_ = '' "

	cQuery +=" UNION ALL"

	cQuery +=" SELECT DISTINCT E2_PREFIXO AS PREF,"
	cQuery +=" E2_NUM AS NUM,"
	cQuery +=" E2_PARCELA AS PARCELA,"
	cQuery +=" E2_TIPO AS TIPO,"
	cQuery +=" E2_FORNECE + ' - ' + E2_LOJA + ' - ' + E2_NOMFOR AS FORNECEDOR,"
	cQuery +=" CAST(E2_EMISSAO AS DATE) AS EMISSAO,"
	cQuery +=" CAST(E2_VENCTO AS DATE) AS VENCIMENTO,"
	cQuery +=" CAST(E2_VALOR AS MONEY) AS VALOR,"
	cQuery +=" E2_FATURA AS FATURA FROM SE2010"

	cQuery +=" WHERE E2_TIPO = 'FT'"
	cQuery +=" AND E2_NUM IN ('"+cDoc+"')"
	cQuery +=" AND E2_EMISSAO BETWEEN '"+diniPT+"' AND '"+dfimPT+"'"
	cQuery +=" AND E2_FILIAL = '"+nFilial+"'"
	cQuery +=" AND D_E_L_E_T_ = '' "


	cQuery := ChangeQuery(cQuery)
	tclink()

	cAliasTFat:= GetNextAlias("SE2010")
	TcQuery cQuery new ALIAS cAliasTFat


	While !cAliasTFat->(EOF())
		
		
		aadd(aDados,{Alltrim(cAliasTFat->PREF),Alltrim(cAliasTFat->NUM),Alltrim(cAliasTFat->PARCELA),(cAliasTFat->TIPO),(cAliasTFat->FORNECEDOR),(cAliasTFat->EMISSAO),(cAliasTFat->VENCIMENTO),DEC_CREATE( (cAliasTFat->VALOR), 18, 2)})

		cAliasTFat->(dbSkip()) //Anda 1 registro pra frente
	EndDo

	//AFill(aWRCPM056,cAliasTFat->USR_FILIAL,6,1)       //6

	cAliasTFat->(dbCloseArea())

Return(aDados)

//------------------------------------------------------------------------------------------
// Criar RELATORIO EM PDF 
//------------------------------------------------------------------------------------------
	
Static Function ReportDef()	
	Local oReport
	Local oSection
	
	Local texto := ""
	texto += "Filial: "+nFilial
    texto += " | Periodo entre: ["+Day2Str(dDiaini)+'/'+	Month2Str(dDiaini)+'/'+Year2Str(dDiaini)
    texto +="] e ["+Day2Str(dDiafim)+'/'+	Month2Str(dDiafim)+'/'+Year2Str(dDiafim)
	texto +="] | Documento: "+cDoc
	// Local oSection1
	// Local oSection2
	
	oReport:= TReport():New("Titulo X Fatura"," Relatorio do Financeiro - PLENA",,{|oReport| PrintReport(oReport)},"")
	oReport:SetLandscape()    
	oReport:HideParamPage()	
	

	oSection:= TRSection():New(oReport,"Cliente: ",{},{})
    TRCell():New(oSection,"COL1" 	,,"","@!",15,/*lPixel*/,/*{|| code-block de impressao }*/)
    TRCell():New(oSection,"COL2" 	,,"","@!",15,/*lPixel*/,/*{|| code-block de impressao }*/)
    TRCell():New(oSection,"COL3" 	,,"","@!",25,/*lPixel*/,/*{|| code-block de impressao }*/)
    TRCell():New(oSection,"COL4" 	,,"","@!",15,/*lPixel*/,/*{|| code-block de impressao }*/)
    TRCell():New(oSection,"COL5" 	,,"","@!",50,/*lPixel*/,/*{|| code-block de impressao }*/)
    TRCell():New(oSection,"COL6" 	,,"","@!",15,/*lPixel*/,/*{|| code-block de impressao }*/)
    TRCell():New(oSection,"COL7" 	,,"","@!",15,/*lPixel*/,/*{|| code-block de impressao }*/)
    TRCell():New(oSection,"COL8" 	,,"","@!",15,/*lPixel*/,/*{|| code-block de impressao }*/)
	oSection:SetLineStyle()
	oReport:SetPageFooter(3,{|| oReport:Say(oReport:Row(),10,texto,,,,)})

	
     		
Return oReport
	
Static Function PrintReport(oReport)
	Local oSection := oReport:Section(1)
	
    Local  i 
	
	oSection:SetTotalInLine(.F.)
	
	// aadd(aDados,{"28154847000101","000001","01","NOME EMPRESA 1","SAO PAULO"})
	// aadd(aDados,{"28154847000102","000002","01","NOME EMPRESA 2","SAO PAULO"})
	// aadd(aDados,{"28154847000103","000003","01","NOME EMPRESA 3","SAO PAULO"})
	// aadd(aDados,{"28154847000104","000004","01","NOME EMPRESA 4","RIO DE JANEIRO"})
	
	oReport:SetMeter(Len(aDados))
	
	oReport:IncMeter()		
	oSection:Init()

            oReport:IncMeter()		
            oSection:Cell("COL1"):SetValue("Prefixo")//, "@R 99.999.999/9999-99"))
            oSection:Cell("COL2"):SetValue("Numero")
            oSection:Cell("COL3"):SetValue("Parcela")
            oSection:Cell("COL4"):SetValue("Tipo")
            oSection:Cell("COL5"):SetValue("Fornecedor")
            oSection:Cell("COL6"):SetValue("Emissao")
            oSection:Cell("COL7"):SetValue("Vencimento")
            oSection:Cell("COL8"):SetValue("Valor")
            oSection:PrintLine()		
            oReport:ThinLine()
    

        For i:= 1 to len(aDados)
            If oReport:Cancel()
                Exit
            EndIf
            
            oReport:IncMeter()		
            //oSection:Cell("GRUPO"):SetValue(transform(aDados[1,1], "@R 99.999.999/9999-99"))
            oSection:Cell("COL1"):SetValue(aDados[i,1])
            oSection:Cell("COL2"):SetValue(aDados[i,2])
            oSection:Cell("COL3"):SetValue(aDados[i,3])
            oSection:Cell("COL4"):SetValue(aDados[i,4])
            oSection:Cell("COL5"):SetValue(aDados[i,5])
            oSection:Cell("COL6"):SetValue(aDados[i,6])
            oSection:Cell("COL7"):SetValue(aDados[i,7])
            oSection:Cell("COL8"):SetValue(transform(aDados[i,8], "@E 999,999.99"))
            oSection:PrintLine()		
            oReport:ThinLine()
        Next  
	oReport:ThinLine()
	oSection:Finish()

Return
//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------
