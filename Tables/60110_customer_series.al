tableextension 60104 Customer_Series extends "Sales & Receivables Setup"

{
    // *** Field added to setup Number series for Customer quote page // ***
    fields
    {
        field(70004; "Customer quote id"; code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
            Editable = true;
            Width = 1;
            Enabled = true;
        }
    }
}