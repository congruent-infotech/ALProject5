page 60105 "Customer Quote"
{
    PageType = Document;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Customer Header";
    SourceTableView = WHERE("Document Type" = FILTER(Quote));

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    Visible = False;
                    ApplicationArea = All;
                    trigger OnValidate()
                    var
                        SalesSetup: Record "Sales & Receivables Setup";
                        NoSeriesMgt: Codeunit NoSeriesManagement;
                    BEGIN
                        IF Rec."No." <> xRec."No." THEN BEGIN
                            SalesSetup.GET;
                            NoSeriesMgt.TestManual(SalesSetup."Customer quote id");
                            Rec."No." := '';
                        END;
                    end;
                }
                field("Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Lookup = true;
                    TableRelation = Customer."No.";
                }
                field("Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = All;

                }
                field("External Document No"; Rec."External Document No.")
                {
                    ApplicationArea = All;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = All;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = All;
                }
                field("Req. Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = All;
                }
                field("Quote Valid Upto Date"; Rec."Quote Valid Until Date")
                {
                    ApplicationArea = All;

                }
                field("Status"; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Address"; Rec."Sell-to Address")
                {
                    Caption = 'Address';
                    ApplicationArea = All;
                }
                field("Address2"; Rec."Sell-to Address 2")
                {
                    Caption = 'Address2';
                    ApplicationArea = All;
                }
                field("City"; Rec."Sell-to City")
                {
                    Caption = 'City';
                    ApplicationArea = All;
                }
                field("State"; Rec."Sell-to County")
                {
                    Caption = 'State';
                    ApplicationArea = All;
                }
                field("Zip Code"; Rec."Sell-to Post Code")
                {
                    Caption = 'Zip Code';
                    ApplicationArea = All;
                }
                field("Country&Region"; Rec."Sell-to Country/Region Code")
                {
                    Caption = 'Country/Region';
                    ApplicationArea = All;
                }
                field("Contact No."; Rec."Bill-to Contact No.")
                {
                    Caption = 'Address2';
                    ApplicationArea = All;
                }
                field("Phone No."; SellToContact."Phone No.")
                {
                    Caption = 'Phone No.';
                    ApplicationArea = All;
                }
                field("Mobile Phone No."; SellToContact."Mobile Phone No.")
                {
                    Caption = 'Mobile Phone No.';
                    ApplicationArea = All;
                }
                field("Email"; SellToContact."E-Mail")
                {
                    Caption = 'Email';
                    ApplicationArea = All;
                }
                field("Contact "; Rec."Sell-to Contact")
                {
                    Caption = 'Contact';
                    ApplicationArea = All;
                }
                field("Customer Template Code"; Rec."Sell-to Customer Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Template Code';
                }
                field("No. of Archived Versions"; Rec."No. of Archived Versions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Archived Versions';
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Suite;
                    Caption = 'Your Reference';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Salesperson Code';
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign No.';
                }
                field("Opportunity No."; Rec."Opportunity No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunity No.';
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    AccessByPermission = TableData "Responsibility Center" = R;
                    ApplicationArea = Suite;
                    Caption = 'Responsibility Center';
                }
                field("Assigned User ID"; rec."Assigned User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Id';
                }
            }
            group(Lines)
            {
                part(Quote; "Customer Subform")
                {
                    Caption = 'Lines';
                    SubPageLink = "Document No." = field("No.");
                    ApplicationArea = Basic, Suite;
                    Editable = (Rec."Sell-to Customer No." <> '') OR (Rec."Sell-to Customer Template Code" <> '') OR (Rec."Sell-to Contact No." <> '');
                    Enabled = (Rec."Sell-to Customer No." <> '') OR (Rec."Sell-to Customer Template Code" <> '') OR (Rec."Sell-to Contact No." <> '');
                    UpdatePropagation = Both;
                }

            }
            group(Invoice)
            {
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = All;
                }
                field("VAT Business Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Lookup = true;
                }
                field("Payment Term Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = All;
                    Lookup = true;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = All;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = All;
                }
                field("Payment Service"; Rec."Payment Service Set ID")
                {
                    ApplicationArea = All;
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = All;
                }
                field("Customergroup Code"; Rec."Customer Price Group")
                {
                    ApplicationArea = All;
                }
                field("Department Code"; Rec."Dimension Set ID")
                {
                    ApplicationArea = All;
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = All;
                }
            }
            group("Shipping and Billing")
            {
                field("Ship-To"; Rec."Ship-to Address")
                {
                    ApplicationArea = All;
                }
                field("Contact"; Rec."Bill-to Contact No.")
                {
                    ApplicationArea = All;
                }
                field("Bill-To"; Rec."Bill-to Address")
                {
                    ApplicationArea = All;
                }
                field("Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = All;

                }
                field("Country/Region"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = All;

                }
                field("Contact Name"; Rec."Bill-to Contact")
                {
                    ApplicationArea = All;
                    Caption = 'Contact';
                }
            }
        }

         // *** Factbox can be added in the below area  *** //
        area(FactBoxes)
        {
            part(Statistic; "Customer Statistics FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = FIELD("Sell-to Customer No.");
            }
        }
    }

    actions
    {
        // Adds the action called "My Actions" to the Action menu 
        area(Processing)
        {
            
            action("Make Order")
            {
                Promoted = true;
                PromotedCategory = Process;
                Image = MakeOrder;
                ApplicationArea = All;
                trigger OnAction()
                begin
                    if PrePostApprovalCheckSales(Rec) then
                        CODEUNIT.Run(CODEUNIT::"Customer-Quote to Order (Y/N)", Rec);
                end;
            }

        }

        area(Navigation)
        {
            // Adds the action called "My Navigate" to the Navigate menu. 
            action("Navigate")
            {
                ApplicationArea = All;
                RunObject = page "Customer Card";
            }
        }
    }

    var
        SellToContact: Record Contact;
        SalesPrePostCheckErr: Label 'Sales %1 %2 must be approved and released before you can perform this action.', Comment = '%1=document type, %2=document no., e.g. Sales Order 321 must be approved...';
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowManagement: Codeunit "Workflow Management";

    procedure PrePostApprovalCheckSales(var SalesHeader: Record "Customer Header"): Boolean
    begin
        OnBeforePrePostApprovalCheckSales(SalesHeader);
        if IsSalesHeaderPendingApproval(SalesHeader) then
            Error(SalesPrePostCheckErr, SalesHeader."Document Type", SalesHeader."No.");

        exit(true);
    end;


    procedure IsSalesApprovalsWorkflowEnabled(var SalesHeader: Record "Customer Header"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(SalesHeader, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode));
    end;

    procedure IsSalesHeaderPendingApproval(var SalesHeader: Record "Customer Header"): Boolean
    begin
        if SalesHeader.Status <> SalesHeader.Status::Open then
            exit(false);

        exit(IsSalesApprovalsWorkflowEnabled(SalesHeader));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrePostApprovalCheckSales(var SalesHeader: Record "Customer Header")
    begin
    end;
}

