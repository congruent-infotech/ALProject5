page 60103 "Customer Quote List"
{

    ApplicationArea = Basic, Suite;
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,New Document,Vendor,Navigate';
    RefreshOnActivate = true;
    UsageCategory = Lists;
    SourceTable = "Customer Header";
    CardPageId = "Customer Quote";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
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
                    Editable = true;
                }

                field("Contact"; Rec."Sell-to Contact")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
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
                field("Amount"; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field("User"; Rec."Assigned User ID")
                {
                    ApplicationArea = All;

                }
                field("Quote Valid Until Date"; Rec."Quote Valid Until Date")
                {
                    ApplicationArea = All;
                }
            }
        }

        // *** Factbox can be added in the below area  *** //
        area(FactBoxes)
        {
             systempart(links; Links)
            {            
                ApplicationArea = all;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = all;
            }
            part(Sales_Hist; "Sales History")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("Sell-to Customer No.");
            }
            part(Statistics; "Customer Statistics FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = FIELD("Sell-to Customer No.");

            }
            part(SalesHistory; "Sales order history")
            {
                ApplicationArea = all;
                SubPageLink = "Sell-to Customer No." = field("Sell-to Customer No.");
            }
        }
    }

}