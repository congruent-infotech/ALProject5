codeunit 60112 "Customer-Quote to Order (Y/N)"
{
    TableNo = "Customer Header";
//********* Code Unit to proceed with the pop-up for Quote to Order Conversion *********//
    trigger OnRun()
  //***Quote to order conversion Popup Logic ***//
    var
        OfficeMgt: Codeunit "Office Management";
        SalesOrder: Page "Sales Order";
        OpenPage: Boolean;
    begin
        if IsOnRunHandled(Rec) then
            exit;
        Rec.TestField("Document Type", REC."Document Type"::Quote);
        if not ConfirmConvertToOrder(Rec) then
            exit;
        SalesQuoteToOrder.Run(Rec);
        SalesQuoteToOrder.GetSalesOrderHeader(SalesHeader);
        Commit();
        OnAfterSalesQuoteToOrderRun(SalesHeader);
        //*** Logic to open the converted quote automatically ***//
        if GuiAllowed then
            if OfficeMgt.AttachAvailable then
                OpenPage := true
            else
            SalesHeader.SetCurrentKey("Quote No.","Document Type");
            SalesHeader.SetRange("Document Type",SalesHeader."Document Type"::Order);
            SalesHeader.SetRange("Quote No.",REC."No.");
            If SalesHeader.Find('-') THEN
            OpenPage := Confirm(StrSubstNo(OpenNewInvoiceQst,SalesHeader."No."), true);
        if OpenPage then begin
            Clear(SalesOrder);
            SalesOrder.CheckNotificationsOnce;
            SalesOrder.SetRecord(SalesHeader);
            SalesOrder.Run;
        end;
    end;

//Global variables used
    var
        ConfirmConvertToOrderQst: Label 'Do you want to convert the quote to an order?';
        OpenNewInvoiceQst: Label 'The quote has been converted to order %1. Do you want to open the new order?', Comment = '%1 = No. of the new sales order document.';
        SalesHeader: Record "Sales Header";
        SalesHeader2: RecordRef;
        Sales: FieldRef;
        SalesQuoteToOrder: Codeunit "Customer-Quote to Order";

// Procedures used for Popup and Quote Conversion
    local procedure IsOnRunHandled(var SalesHeader: Record "Customer Header") IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeRun(SalesHeader, IsHandled);
        exit(IsHandled);
    end;

    local procedure ConfirmConvertToOrder(SalesHeader: Record "Customer Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmConvertToOrder(SalesHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if GuiAllowed then
            if not Confirm(ConfirmConvertToOrderQst, false) then
                exit(false);
        exit(true);
    end;

// *** Event Procedures to execute like a trigger before a function call. ***//
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesQuoteToOrderRun(var SalesHeader2: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var SalesHeader: Record "Customer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmConvertToOrder(SalesHeader: Record "Customer Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

