pageextension 60104 Customer_Series extends "Sales & Receivables Setup"
{
    // To setup Number series for Customer Quote
    layout
    {
        addafter("Invoice Nos.")
        {
            field("Customer quote id"; Rec."Customer quote id")
            {
                ApplicationArea = all;
            }
        }
    }
}