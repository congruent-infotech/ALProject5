Page 60110 "Sales order history"
{
// *** Factbox part to add in a page to additional information to the user about Order History *** //
    Caption = 'Sales Order History';
    LinksAllowed = true;
    PageType = CardPart;
    SourceTable = "Sales Header";


    Layout
    {
        area(content)
        {

            field("Customer Detail"; Rec."Sell-to Customer No." + '-' + Rec."Sell-to Customer Name")
            {
                ApplicationArea = All;
                Caption = 'Customer';
                ShowCaption = true;
                Style = Strong;
            }

            repeater(control27)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = all;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = all;
                }
            }
        }
    }


}