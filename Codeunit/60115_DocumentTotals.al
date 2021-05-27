codeunit 60115 "DocumentTotals"
{
// *** Codeunit to Calculate Line Amount in Quote lines *** //
    trigger OnRun()
    begin
    end;
    var
        TotalVATLbl: Label 'Total VAT';
        TotalAmountInclVatLbl: Label 'Total Incl. VAT';
        TotalAmountExclVATLbl: Label 'Total Excl. VAT';
        TotalLineAmountLbl: Label 'Subtotal';
        TotalsUpToDate: Boolean;


// *** To calculate Sales amount *** //
    procedure CalcTotalSalesAmountOnlyDiscountAllowed(SalesLine: Record "Customer Line"): Decimal
    var
        TotalSalesLine: Record "Customer Line";
    begin
        with TotalSalesLine do begin
            SetRange("Document Type", SalesLine."Document Type");
            SetRange("Document No.", SalesLine."Document No.");
            SetRange("Allow Invoice Disc.", true);
            CalcSums("Line Amount");
            exit("Line Amount");
        end;
    end;


    procedure SalesDocTotalsNotUpToDate()
    begin
        TotalsUpToDate := false;
    end;

// *** Procedures for Captions for Amount and Discount fields in Subform page based on Currency code *** //
    local procedure GetCaptionWithCurrencyCode(CaptionWithoutCurrencyCode: Text; CurrencyCode: Code[10]): Text
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode = '' then begin
            GLSetup.Get();
            CurrencyCode := GLSetup.GetCurrencyCode(CurrencyCode);
        end;

        if CurrencyCode <> '' then
            exit(CaptionWithoutCurrencyCode + StrSubstNo(' (%1)', CurrencyCode));

        exit(CaptionWithoutCurrencyCode);
    end;



    local procedure GetCaptionWithVATInfo(CaptionWithoutVATInfo: Text; IncludesVAT: Boolean): Text
    begin
        if IncludesVAT then
            exit('2,1,' + CaptionWithoutVATInfo);

        exit('2,0,' + CaptionWithoutVATInfo);
    end;

    local procedure GetCaptionClassWithCurrencyCode(CaptionWithoutCurrencyCode: Text; CurrencyCode: Code[10]): Text
    begin
        exit('3,' + GetCaptionWithCurrencyCode(CaptionWithoutCurrencyCode, CurrencyCode));
    end;

    procedure SalesDeltaUpdateTotals(var SalesLine: Record "Customer Line"; var xSalesLine: Record "Customer Line"; var TotalSalesLine: Record "Customer Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    var
        InvDiscountBaseAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesDeltaUpdateTotals(SalesLine, xSalesLine, TotalSalesLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct, IsHandled);
        if IsHandled then
            exit;

        TotalSalesLine."Line Amount" += SalesLine."Line Amount" - xSalesLine."Line Amount";
        TotalSalesLine."Amount Including VAT" += SalesLine."Amount Including VAT" - xSalesLine."Amount Including VAT";
        TotalSalesLine.Amount += SalesLine.Amount - xSalesLine.Amount;
        VATAmount := TotalSalesLine."Amount Including VAT" - TotalSalesLine.Amount;
        if SalesLine."Inv. Discount Amount" <> xSalesLine."Inv. Discount Amount" then begin
            if (InvoiceDiscountPct > -0.01) and (InvoiceDiscountPct < 0.01) then // To avoid decimal overflow later
                InvDiscountBaseAmount := 0
            else
                InvDiscountBaseAmount := InvoiceDiscountAmount / InvoiceDiscountPct * 100;
            InvoiceDiscountAmount += SalesLine."Inv. Discount Amount" - xSalesLine."Inv. Discount Amount";
            if (InvoiceDiscountAmount = 0) or (InvDiscountBaseAmount = 0) then
                InvoiceDiscountPct := 0
            else
                InvoiceDiscountPct := Round(100 * InvoiceDiscountAmount / InvDiscountBaseAmount, 0.00001);
        end;

        OnAfterSalesDeltaUpdateTotals(SalesLine, xSalesLine, TotalSalesLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
    end;

    procedure GetTotalLineAmountWithVATAndCurrencyCaption(CurrencyCode: Code[10]; IncludesVAT: Boolean): Text
    begin
        exit(GetCaptionWithCurrencyCode(CaptionClassTranslate(GetCaptionWithVATInfo(TotalLineAmountLbl, IncludesVAT)), CurrencyCode));
    end;

    procedure GetInvoiceDiscAmountWithVATAndCurrencyCaption(InvDiscAmountCaptionClassWithVAT: Text; CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionWithCurrencyCode(InvDiscAmountCaptionClassWithVAT, CurrencyCode));
    end;

    procedure GetTotalVATCaption(CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionClassWithCurrencyCode(TotalVATLbl, CurrencyCode));
    end;

    procedure GetTotalInclVATCaption(CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionClassWithCurrencyCode(TotalAmountInclVatLbl, CurrencyCode));
    end;

    procedure GetTotalExclVATCaption(CurrencyCode: Code[10]): Text
    begin
        exit(GetCaptionClassWithCurrencyCode(TotalAmountExclVATLbl, CurrencyCode));
    end;

// *** Event Procedures to execute like a trigger before a function call. ***//
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesDeltaUpdateTotals(var SalesLine: Record "Customer Line"; var xSalesLine: Record "Customer Line"; var TotalSalesLine: Record "Customer Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesDeltaUpdateTotals(var SalesLine: Record "Customer Line"; var xSalesLine: Record "Customer Line"; var TotalSalesLine: Record "Customer Line"; var VATAmount: Decimal; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountPct: Decimal; var IsHandled: Boolean)
    begin
    end;


}