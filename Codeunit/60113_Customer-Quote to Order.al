codeunit 60113 "Customer-Quote to Order"
{
    TableNo = "Customer Header";
//********* Code Unit to Move Customer Quote data to Sales order table*********//
    trigger OnRun()
    var
        Cust: Record Customer;
        SalesCommentLine: Record "Sales Comment Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        RecordLinkManagement: Codeunit "Record Link Management";
        ShouldRedistributeInvoiceAmount: Boolean;
        IsHandled: Boolean;
        
    begin
        //***Quote dataValidations before Code Move***//
        OnBeforeOnRun(Rec);
        Rec.TestField("Document Type", Rec."Document Type"::Quote);
        Cust.Get(Rec."Sell-to Customer No.");
        Cust.CheckBlockedCustOnDocs(Cust, Rec."Document Type"::Order, true, false);
        if Rec."Sell-to Customer No." <> Rec."Bill-to Customer No." then begin
            Cust.CheckBlockedCustOnDocs(Cust, Rec."Document Type"::Order, true, false);
            Cust.Get(Rec."Sell-to Customer No.");
            Cust.CheckBlockedCustOnDocs(Cust, Rec."Document Type"::Order, true, false);
            Rec.CalcFields("Amount Including VAT", "Work Description");
        end;
        CreateSalesHeader(Rec, Cust."Prepayment %");
        TransferQuoteToOrderLines(SalesQuoteLine, Rec, SalesOrderLine, SalesOrderHeader, Cust);
        OnAfterInsertAllSalesOrderLines(SalesOrderLine, Rec);
        SalesSetup.Get();

// *** Posting Date Setup *** //
        if SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" then begin
            SalesOrderHeader."Posting Date" := 0D;
            SalesOrderHeader.Modify();
        end;

        SalesCommentLine.CopyComments(Rec."Document Type".AsInteger(), SalesOrderHeader."Document Type".AsInteger(), Rec."No.", SalesOrderHeader."No.");
        RecordLinkManagement.CopyLinks(Rec, SalesOrderHeader);
        CopyApprovalEntryQuoteToOrder(Rec, SalesOrderHeader);

        IsHandled := false;
        OnBeforeDeleteSalesQuote(Rec, SalesOrderHeader, IsHandled, SalesQuoteLine);
        if not IsHandled then begin
            ApprovalsMgmt.DeleteApprovalEntries(REC.RecordId);
            Rec.DeleteLinks;
            Rec.Delete;
            SalesQuoteLine.DeleteAll();
        end;

        if not ShouldRedistributeInvoiceAmount then
            SalesCalcDiscountByType.ResetRecalculateInvoiceDisc(SalesOrderHeader);

        OnAfterOnRun(Rec, SalesOrderHeader);
 
    end;

    var
        SalesQuoteLine: Record "Customer Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";

//***Quote Approval Process during the quote conversion****//
    local procedure CopyApprovalEntryQuoteToOrder(SalesHeader: Record "CUstomer Header"; SalesOrderHeader: Record "Sales Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyApprovalEntryQuoteToOrder(SalesHeader, SalesOrderHeader, IsHandled);
        if not IsHandled then
            ApprovalsMgmt.CopyApprovalEntryQuoteToOrder(SalesHeader.RecordId, SalesOrderHeader."No.", SalesOrderHeader.RecordId);
    end;

//*****Procedure to Move Header information of the quote table to order table ****//
    local procedure CreateSalesHeader(SalesHeader: Record "Customer Header"; PrepmtPercent: Decimal)
    begin
        OnBeforeCreateSalesHeader(SalesHeader);
        with SalesHeader do begin
            SalesOrderHeader."Document Type" := SalesOrderHeader."Document Type"::Order;
            SalesOrderHeader."Sell-to Customer Name" := "Sell-to Customer Name";
            SalesOrderHeader."Sell-to Customer No." := "Sell-to Customer No.";
            SalesOrderHeader."Bill-to Customer No." := "Sell-to Customer No.";
            SalesOrderHeader."Bill-to Name" := "Sell-to Customer Name";
            SalesOrderHeader."Bill-to Name 2" := "Bill-to Name 2";
            SalesOrderHeader."Sell-to Address" := "Sell-to Address";
            SalesOrderHeader."Sell-to Address 2" := "Sell-to Address 2";
            SalesOrderHeader."Sell-to City" := "Sell-to City";
            SalesOrderHeader."Sell-to Contact" := "Sell-to Contact";
            SalesOrderHeader."Sell-to Country/Region Code" := "Sell-to Country/Region Code";
            SalesOrderHeader."Sell-to County" := "Sell-to County";
            SalesOrderHeader."Sell-to E-Mail" := "Sell-to E-Mail";
            SalesOrderHeader."Sell-to Post Code" := "Sell-to Post Code";
            SalesOrderHeader."Sell-to Phone No." := "Sell-to Phone No.";
            SalesOrderHeader."Bill-to Address" := "Bill-to Address";
            SalesOrderHeader."Bill-to Address 2" := "Bill-to Address 2";
            SalesOrderHeader."Bill-to City" := "Bill-to City";
            SalesOrderHeader."Bill-to Contact" := "Bill-to Contact";
            SalesOrderHeader."Bill-to Country/Region Code" := "Bill-to Country/Region Code";
            SalesOrderHeader."Bill-to County" := "Bill-to County";
            SalesOrderHeader."Bill-to Post Code" := "Bill-to Post Code";
            SalesOrderHeader."No." := '';
            SalesOrderHeader."Order Date" := "Order Date";
            SalesOrderHeader."External Document No." := "External Document No.";
            SalesOrderHeader."Document Date" := "Document Date";
            SalesOrderHeader."Requested Delivery Date" := "Requested Delivery Date";
            SalesOrderHeader."Quote Valid until Date" := "Quote Valid Until Date";
            SalesOrderHeader."No. Printed" := 0;
            SalesOrderHeader."Shipment Date" := "Shipment Date";
            SalesOrderHeader."Payment Terms Code" := "Payment Terms Code";
            SalesOrderHeader."Salesperson Code" := "Salesperson Code";
            SalesOrderHeader.Status := SalesOrderHeader.Status::Open;
            SalesOrderHeader."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
            SalesOrderHeader."Gen. Bus. Posting Group" := "Gen. Bus. Posting Group";
            SalesOrderHeader."Due Date" := "Due Date";
            SalesOrderHeader."Quote No." := "No.";
            SalesOrderLine.LockTable();
            OnBeforeInsertSalesOrderHeader(SalesOrderHeader, SalesHeader);
            SalesOrderHeader.Insert(true);
            OnAfterInsertSalesOrderHeader(SalesOrderHeader, SalesHeader);
            SalesOrderHeader."Order Date" := "Order Date";
            if "Posting Date" <> 0D then
            SalesOrderHeader."Posting Date" := "Posting Date";
            SalesOrderHeader.InitFromSalesHeader(SalesOrderHeader);
            SalesOrderHeader."Outbound Whse. Handling Time" := "Outbound Whse. Handling Time";
            SalesOrderHeader.Reserve := Reserve;

            SalesOrderHeader."Prepayment %" := PrepmtPercent;
            if SalesOrderHeader."Posting Date" = 0D then
                SalesOrderHeader."Posting Date" := WorkDate;

            CalcFields("Work Description");
            SalesOrderHeader."Work Description" := "Work Description";

            OnBeforeModifySalesOrderHeader(SalesOrderHeader, SalesHeader);
            OnBeforeModifySalesOrderHeader(SalesOrderHeader, SalesHeader);
            SalesOrderHeader.Modify();
        end;
        OnAfterCreateSalesHeader(SalesOrderHeader, SalesHeader);
    end;



    procedure GetSalesOrderHeader(var SalesHeader2: Record "Sales Header")
    begin
    end;

// **** Procedure to transfer line item details to order *** //
    local procedure TransferQuoteToOrderLines(var SalesQuoteLine: Record "Customer Line"; var SalesQuoteHeader: Record "Customer Header"; var SalesOrderLine: Record "Sales Line"; var SalesOrderHeader: Record "Sales Header"; Customer: Record Customer)
    var
        ATOLink: Record "Assemble-to-Order Link";
        PrepmtMgt: Codeunit "Prepayment Mgt.";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        IsHandled: Boolean;
        ITEM: Record item;
    begin
        SalesQuoteLine.Reset();
        SalesQuoteLine.SetRange("Document Type", SalesQuoteHeader."Document Type");
        SalesQuoteLine.SetRange("Document No.", SalesQuoteHeader."No.");
        OnTransferQuoteToOrderLinesOnAfterSetFilters(SalesQuoteLine, SalesQuoteHeader);
        if SalesQuoteLine.FindSet then
            repeat
                IsHandled := false;
                OnBeforeTransferQuoteLineToOrderLineLoop(SalesQuoteLine, SalesQuoteHeader, SalesOrderHeader, IsHandled);
                if not IsHandled then begin
                    If SalesQuoteLine.Quantity > 0 then
                    SalesOrderLine."Document Type" := SalesOrderHeader."Document Type";
                    SalesOrderLine."Document No." := SalesOrderHeader."No.";
                    SalesOrderLine."Line No." := SalesOrderLine."Line No." + 1;
                    SalesOrderLine."Shortcut Dimension 1 Code" := SalesQuoteLine."Shortcut Dimension 1 Code";
                    SalesOrderLine."Shortcut Dimension 2 Code" := SalesQuoteLine."Shortcut Dimension 2 Code";
                    SalesOrderLine."Dimension Set ID" := SalesQuoteLine."Dimension Set ID";
                    SalesOrderLine."Transaction Type" := SalesOrderHeader."Transaction Type";
                    SalesOrderLine."Planned Delivery Date" := SalesOrderHeader."Order Date";
                    SalesOrderLine."Planned Shipment Date" := SalesOrderHeader."Shipment Date";
                    SalesOrderLine."Shipment Date" := SalesOrderHeader."Shipment Date";
                    SalesOrderLine."Type" := SalesQuoteLine.Type;
                    SalesOrderLine."No." := SalesQuoteLine."No.";
                    SalesOrderLine.Description := SalesQuoteLine.Description;
                    SalesOrderLine."Location Code" := SalesQuoteLine."Location Code";
                    SalesOrderLine."Quantity" := SalesQuoteLine.Quantity;
                    SalesOrderLine."Unit Of Measure Code" := SalesQuoteLine."Unit of Measure Code";
                    SalesOrderLine."Unit Price" := SalesQuoteLine."Unit Price";
                    SalesOrderLine."Line Amount" := SalesQuoteLine."Line Amount";
                    SalesOrderLine.Validate(Quantity);
                    SalesOrderLine."Qty. to Ship" := SalesOrderLine.Quantity;
                    SalesOrderline."Qty. to Invoice" := SalesOrderLine.Quantity;
                    SalesOrderLine."VAT Bus. Posting Group" := SalesQuoteLine."VAT Bus. Posting Group";
                    SalesOrderLine."Gen. Prod. Posting Group" := SalesQuoteLine."Gen. Prod. Posting Group";
                    Salesorderline."Gen. Bus. Posting Group" := SalesOrderHeader."Gen. Bus. Posting Group";
                    SalesOrderLine."VAT Prod. Posting Group" := SalesQuoteLine."VAT Prod. Posting Group";
                    SalesOrderLine.Amount := SalesQuoteLine.Amount;
                    SalesOrderLine."Amount Including VAT" := Salesquoteline."Line Amount";//+ SalesOrderLine."VAT Base Amount";
                    SalesOrderLine.Amount := SalesOrderLine."Line Amount";
                    SalesOrderLine."Shortcut Dimension 1 Code" := SalesQuoteLine."Shortcut Dimension 1 Code";
                    SalesOrderLine."Shortcut Dimension 2 Code" := SalesQuoteLine."Shortcut Dimension 2 Code";
                    SalesOrderLine."Dimension Set ID" := SalesQuoteLine."Dimension Set ID";
                    SalesOrderLine."Transaction Type" := SalesOrderHeader."Transaction Type";
                    SalesOrderLine."Quantity (Base)" := (SalesOrderLine."Quantity");
                    if SalesOrderLine."No." <> '' then
                        SalesOrderLine.DefaultDeferralCode;
                    OnBeforeInsertSalesOrderLine(SalesOrderLine, SalesOrderHeader, SalesQuoteLine, SalesQuoteHeader);
                    SalesOrderLine.Insert();
                    OnAfterInsertSalesOrderLine(SalesOrderLine, SalesOrderHeader, SalesQuoteLine, SalesQuoteHeader);
                    TransferSaleLineToSalesLine(
                      SalesQuoteLine, SalesOrderLine, SalesQuoteLine."Outstanding Qty. (Base)");
                    VerifyQuantity(SalesOrderLine, SalesQuoteLine);
                    if SalesOrderLine.Reserve = SalesOrderLine.Reserve::Always then
                        SalesOrderLine.AutoReserve();
                end;
            until SalesQuoteLine.Next = 0;
        SalesOrderLine.Reset();
    end;

// Procedure to make reservation when a quote is converted to order //
    procedure TransferSaleLineToSalesLine(var OldSalesLine: Record "Customer Line"; var NewSalesLine: Record "Sales Line"; TransferQty: Decimal)
    var
        OldReservEntry: Record "Reservation Entry";
        ReservStatus: Enum "Reservation Status";
        IsHandled: Boolean;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        IsHandled := false;
        OnBeforeTransferSaleLineToSalesLine(OldSalesLine, NewSalesLine, TransferQty, IsHandled);
        if IsHandled then
            exit;

        if not FindReservEntry(OldSalesLine, OldReservEntry) then
            exit;

        OldReservEntry.Lock;

        NewSalesLine.TestItemFields(OldSalesLine."No.", OldSalesLine."Variant Code", OldSalesLine."Location Code");

        for ReservStatus := ReservStatus::Reservation to ReservStatus::Prospect do begin
            if TransferQty = 0 then
                exit;
            OldReservEntry.SetRange("Reservation Status", ReservStatus);
            if OldReservEntry.FindSet then
                repeat
                    OldReservEntry.TestItemFields(OldSalesLine."No.", OldSalesLine."Variant Code", OldSalesLine."Location Code");
                    if (OldReservEntry."Reservation Status" = OldReservEntry."Reservation Status"::Prospect) and
                       (OldSalesLine."Document Type" in [OldSalesLine."Document Type"::Quote,
                                                         OldSalesLine."Document Type"::"Blanket Order"])
                    then
                        OldReservEntry."Reservation Status" := OldReservEntry."Reservation Status"::Surplus;

                    TransferQty :=
                        CreateReservEntry.TransferReservEntry(DATABASE::"Sales Line",
                            NewSalesLine."Document Type".AsInteger(), NewSalesLine."Document No.", '', 0,
                            NewSalesLine."Line No.", NewSalesLine."Qty. per Unit of Measure", OldReservEntry, TransferQty);

                until (OldReservEntry.Next = 0) or (TransferQty = 0);
        end;
    end;

// *** To Verify quantity in the line *** //
    procedure VerifyQuantity(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Customer Line")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
        Blocked: Boolean;
        ReservMgt: Codeunit "Reservation Management";
    begin
        IsHandled := false;
        OnBeforeVerifyQuantity(NewSalesLine, IsHandled);
        if IsHandled then
            exit;

        if Blocked then
            exit;

        with NewSalesLine do begin
            if Type <> Type::Item then
                exit;
            if "Document Type" = OldSalesLine."Document Type" then
                if "Line No." = OldSalesLine."Line No." then
                    if "Quantity (Base)" = OldSalesLine."Quantity (Base)" then
                        exit;
            if "Line No." = 0 then
                if not SalesLine.Get("Document Type", "Document No.", "Line No.") then
                    exit;
            ReservMgt.SetReservSource(NewSalesLine);
            if "Qty. per Unit of Measure" <> OldSalesLine."Qty. per Unit of Measure" then
                ReservMgt.ModifyUnitOfMeasure;
            if "Outstanding Qty. (Base)" * OldSalesLine."Outstanding Qty. (Base)" < 0 then
                ReservMgt.DeleteReservEntries(true, 0)
            else
                ReservMgt.DeleteReservEntries(false, "Outstanding Qty. (Base)");
            ReservMgt.ClearSurplus;
            ReservMgt.AutoTrack("Outstanding Qty. (Base)");
            AssignForPlanning(NewSalesLine);
        end;
    end;

    // **** To find and filter Reservation item entries *** //
    procedure FindReservEntry(SalesLine: Record "Customer Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.InitSortingAndFilters(false);
        SalesLine.SetReservationFilters(ReservEntry);
        exit(ReservEntry.FindLast);
    end;


// *** Assign Quantities for planning after quote conversion *** ///
    procedure AssignForPlanning(var SalesLine: Record "Sales Line")
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        with SalesLine do begin
            if "Document Type" <> "Document Type"::Order then
                exit;
            if Type <> Type::Item then
                exit;
            if "No." <> '' then
                PlanningAssignment.ChkAssignOne("No.", "Variant Code", "Location Code", "Shipment Date");
        end;
    end;

// *** Event Procedures to execute like a trigger before a function call. ***//
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferSaleLineToSalesLine(var OldSalesLine: Record "Customer Line"; var NewSalesLine: Record "Sales Line"; var TransferQty: Decimal; var IsHandled: Boolean);
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyQuantity(var NewSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesHeader(var SalesHeader: Record "Customer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesQuote(var QuoteSalesHeader: Record "Customer Header"; var OrderSalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesQuoteLine: Record "Customer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; var SalesQuoteHeader: Record "Customer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; SalesQuoteHeader: Record "Customer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesOrderLine(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; SalesQuoteLine: Record "Customer Line"; SalesQuoteHeader: Record "Customer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; SalesQuoteHeader: Record "CUstomer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAllSalesOrderLines(var SalesOrderLine: Record "Sales Line"; SalesQuoteHeader: Record "Customer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var SalesHeader: Record "Customer Header"; var SalesOrderHeader: Record "Sales Header")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyApprovalEntryQuoteToOrder(var QuoteSalesHeader: Record "Customer Header"; var OrderSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesOrderLine(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; SalesQuoteLine: Record "Customer Line"; SalesQuoteHeader: Record "Customer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "CUstomer Header")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferQuoteLineToOrderLineLoop(var SalesQuoteLine: Record "Customer Line"; var SalesQuoteHeader: Record "Customer Header"; var SalesOrderHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferQuoteToOrderLinesOnAfterSetFilters(var SalesQuoteLine: Record "Customer Line"; var SalesQuoteHeader: Record "Customer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesHeader(var SalesOrderHeader: Record "Sales Header"; SalesHeader: Record "Customer Header")
    begin
    end;
}


