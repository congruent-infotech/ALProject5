table 60102 "Customer Line"
{
    // *** New table to store line information of the quote *** // 
    Caption = 'Customer Line';
    DrillDownPageID = "Customer Lines";
    LookupPageID = "Customer Lines";

    fields
    {
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';

        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';

        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';
        }
        field(6; "No."; Code[20])
        {
            TableRelation = IF (Type = CONST(" ")) "Standard Text"
            ELSE
            IF (Type = CONST("G/L Account"),
                                     "System-Created Entry" = CONST(false)) "G/L Account"
                                      WHERE("Direct Posting" = CONST(true),
                                            "Account Type" = CONST(Posting),
                                            Blocked = CONST(false))
            ELSE
            IF (Type = CONST("G/L Account"),
                    "System-Created Entry" = CONST(true)) "G/L Account"
            ELSE
            IF (Type = CONST(Resource)) Resource
            ELSE
            IF (Type = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF (Type = CONST("Charge (Item)")) "Item Charge"
            ELSE
            IF (Type = CONST(Item),
            "Document Type" = FILTER(<> "Credit Memo" & <> "Return Order")) Item WHERE(Blocked = CONST(false), "Sales Blocked" = CONST(false))
            ELSE
            IF (Type = CONST(Item), "Document Type" = FILTER("Credit Memo" | "Return Order")) Item WHERE(Blocked = CONST(false));
            ValidateTableRelation = false;
            trigger OnValidate()
            var
                Item: Record Item;
                Location: Record Location;
                PostingSetupMGT: Codeunit PostingSetupManagement;
                SalesHeader: Record "Customer Header";
                TempSalesline: Record "Customer line";
                Resource: Record Resource;
                GLAcct: Record "G/L Account";
                FixedAsset: Record "Fixed Asset";
                ChargeItem: Record "Item Charge";
            begin
                IF Rec.Type = Type::Item Then begin
                    item.Get("No.");
                    Description := item.Description;
                    "Unit Price" := item."Unit Price";
                    "Unit of Measure Code" := item."Base Unit of Measure";
                    "Unit of Measure" := item."Base Unit of Measure";
                    "Location Code" := location.Code;
                    "Gen. Prod. Posting Group" := item."Gen. Prod. Posting Group";
                    "VAT Bus. Posting Group" := item."VAT Bus. Posting Gr. (Price)";
                    "VAT Prod. Posting Group" := item."VAT Prod. Posting Group";
                end;
                IF Rec.Type = Type::Resource Then begin
                    Resource.Get("No.");
                    Description := Resource.Name;
                    "Unit Price" := Resource."Unit Price";
                END;
                If Rec.Type = Type::"G/L Account" then begin
                    GLAcct.Get("No.");
                    Description := GLAcct.Name;
                end;
                If Rec.Type = Type::"Fixed Asset" then Begin
                    FixedAsset.Get("No.");
                    Description := FixedAsset.Description;
                End;
                if Type <> Type::" " then begin
                    PostingSetupMgt.CheckGenPostingSetupSalesAccount("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                    PostingSetupMgt.CheckGenPostingSetupCOGSAccount("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                    PostingSetupMgt.CheckVATPostingSetupSalesAccount("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                end;
                GetSalesHeader();
                OnValidateNoOnBeforeInitHeaderDefaults(SalesHeader, Rec);
                InitHeaderDefaults(SalesHeader);
                OnValidateNoOnAfterInitHeaderDefaults(SalesHeader, TempSalesLine);
                if HasTypeToFillMandatoryFields() then begin
                    PlanPriceCalcByField(FieldNo("No."));
                    Validate("Unit of Measure Code");
                    if Quantity <> 0 then begin
                        InitOutstanding();
                        if IsCreditDocType() then
                            InitQtyToReceive
                        else
                            InitQtyToShip;
                    end;
                end;
            end;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location.Code;
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = IF (Type = CONST(Item)) "Inventory Posting Group"
            ELSE
            IF (Type = CONST("Fixed Asset")) "FA Posting Group";
        }
        field(10; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            AccessByPermission = TableData "Sales Shipment Header" = R;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            TableRelation = IF (Type = CONST("G/L Account"), "No." = CONST(''),
                      "System-Created Entry" = CONST(false)) "G/L Account".Name WHERE("Direct Posting" = CONST(true),
                      "Account Type" = CONST(Posting),
                     Blocked = CONST(false))
            ELSE
            IF (Type = CONST("G/L Account"), "No." = CONST(''),
                "System-Created Entry" = CONST(true)) "G/L Account".Name
            ELSE
            IF (Type = CONST(Item), "No." = CONST(''),
                "Document Type" = FILTER(<> "Credit Memo" & <> "Return Order")) Item.Description WHERE(Blocked = CONST(false),
                                                    "Sales Blocked" = CONST(false))
            ELSE
            IF (Type = CONST(Item), "No." = CONST(''), "Document Type" = FILTER("Credit Memo" | "Return Order")) Item.Description WHERE(Blocked = CONST(false))
            ELSE
            IF (Type = CONST(Resource), "No." = CONST('')) Resource.Name
            ELSE
            IF (Type = CONST("Fixed Asset"), "No." = CONST('')) "Fixed Asset".Description
            ELSE
            IF (Type = CONST("Charge (Item)"), "No." = CONST('')) "Item Charge".Description;
            ValidateTableRelation = false;
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';

        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            trigger OnValidate()
            begin
                If (rec.Quantity <> 0) Then begin
                    Rec."Line Amount" := rec.Quantity * rec."Unit Price";
                end;

            end;
        }
        field(16; "Outstanding Quantity"; Decimal)
        {
            Caption = 'Outstanding Quantity';

        }
        field(17; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            trigger OnValidate()
            Var
                UOMMgt: Codeunit "Unit of Measure Management";
                Text005: Label 'You cannot invoice more than %1 units.';
                Text006: Label 'You cannot invoice more than %1 base units.';
            begin
                if "Qty. to Invoice" = MaxQtyToInvoice then
                    "Qty. to Invoice (Base)" :=
                        UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. to Invoice", "Qty. per Unit of Measure");

                if ("Qty. to Invoice" * Quantity < 0) or
                   (Abs("Qty. to Invoice") > Abs(MaxQtyToInvoice))
                then
                    Error(Text005, MaxQtyToInvoice);

                if ("Qty. to Invoice (Base)" * "Quantity (Base)" < 0) or
                   (Abs("Qty. to Invoice (Base)") > Abs(MaxQtyToInvoiceBase))
                then
                    Error(Text006, MaxQtyToInvoiceBase);

                "VAT Difference" := 0;
            end;

        }
        field(18; "Qty. to Ship"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                IsHandled: Boolean;
                Location: Record Location;
                UOMMGT: Codeunit "Unit of Measure Management";
                Text007: Label 'You cannot ship more than %1 units.';
                Text008: Label 'You cannot ship more than %1 base units.';
            begin
                if "Qty. to Ship" = "Outstanding Quantity" then begin
                    "Qty. to Ship (Base)" :=
                        UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. to Ship", "Qty. per Unit of Measure");
                end;

                IsHandled := false;
                OnValidateQtyToShipAfterInitQty(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then begin
                    if ((("Qty. to Ship" < 0) xor (Quantity < 0)) and (Quantity <> 0) and ("Qty. to Ship" <> 0)) or
                       (Abs("Qty. to Ship") > Abs("Outstanding Quantity")) or
                       (((Quantity < 0) xor ("Outstanding Quantity" < 0)) and (Quantity <> 0) and ("Outstanding Quantity" <> 0))
                    then
                        Error(Text007, "Outstanding Quantity");
                    if ((("Qty. to Ship (Base)" < 0) xor ("Quantity (Base)" < 0)) and ("Qty. to Ship (Base)" <> 0) and ("Quantity (Base)" <> 0)) or
                       (Abs("Qty. to Ship (Base)") > Abs("Outstanding Qty. (Base)")) or
                       ((("Quantity (Base)" < 0) xor ("Outstanding Qty. (Base)" < 0)) and ("Quantity (Base)" <> 0) and ("Outstanding Qty. (Base)" <> 0))
                    then
                        Error(Text008, "Outstanding Qty. (Base)");
                end;

                if (CurrFieldNo <> 0) and (Type = Type::Item) and ("Qty. to Ship" < 0) then
                    UpdateQtyToAsmFromSalesLineQtyToShip();
            end;

        }
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';

            trigger OnValidate()
            begin
                Validate("Line Discount %");
            end;
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {

        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';

        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';

        }
        field(28; "Line Discount Amount"; Decimal)
        {

        }
        field(29; Amount; Decimal)
        {

            Caption = 'Amount';
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Editable = false;

            trigger OnValidate()
            Var
                SalesHeader: Record "CUstomer Header";
                Currency: Record Currency;
                SalesTaxCalculate: Codeunit "Sales Tax Calculate";
                Text009: Label ' must be 0 when %1 is %2';

            begin
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            "VAT Base Amount" :=
                              Round(Amount * (1 - SalesHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Round(Amount + "VAT Base Amount" * "VAT %" / 100, Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        if Amount <> 0 then
                            FieldError(Amount,
                              StrSubstNo(
                                Text009, FieldCaption("VAT Calculation Type"),
                                "VAT Calculation Type"));
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            SalesHeader.TestField("VAT Base Discount %", 0);
                            "VAT Base Amount" := Round(Amount, Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Amount +
                              SalesTaxCalculate.CalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", SalesHeader."Posting Date",
                                "VAT Base Amount", "Quantity (Base)", SalesHeader."Currency Factor");
                            OnAfterSalesTaxCalculate(Rec, SalesHeader, Currency);
                            UpdateVATPercent("VAT Base Amount", "Amount Including VAT" - "VAT Base Amount");
                            "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                        end;
                end;

                InitOutstandingAmount();
            end;
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;
            trigger OnValidate()
            Var
                SalesHeader: Record "Customer Header";
                Currency: Record Currency;
                SalesTaxCalculate: Codeunit "Sales Tax Calculate";

            begin
                "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              Round(
                                "Amount Including VAT" /
                                (1 + (1 - SalesHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                                Currency."Amount Rounding Precision");
                            "VAT Base Amount" :=
                              Round(Amount * (1 - SalesHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            SalesHeader.TestField("VAT Base Discount %", 0);
                            Amount :=
                              SalesTaxCalculate.ReverseCalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", SalesHeader."Posting Date",
                                "Amount Including VAT", "Quantity (Base)", SalesHeader."Currency Factor");
                            OnAfterSalesTaxCalculateReverse(Rec, SalesHeader, Currency);
                            UpdateVATPercent(Amount, "Amount Including VAT" - Amount);
                            Amount := Round(Amount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                        end;
                end;
                OnValidateAmountIncludingVATOnAfterAssignAmounts(Rec, Currency);
                InitOutstandingAmount();
            end;

        }
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
        }
        field(34; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';

        }
        field(35; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';

        }
        field(36; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';

        }
        field(37; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';

        }
        field(38; "Appl.-to Item Entry"; Integer)
        {

            Caption = 'Appl.-to Item Entry';


        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {

        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {

        }
        field(42; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';

        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Job No.';

        }
        field(52; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';

        }
        field(56; "Recalculate Invoice Disc."; Boolean)
        {
            Caption = 'Recalculate Invoice Disc.';
            Editable = false;
        }
        field(57; "Outstanding Amount"; Decimal)
        {

        }
        field(58; "Qty. Shipped Not Invoiced"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invoiced';

        }
        field(59; "Shipped Not Invoiced"; Decimal)
        {

            Caption = 'Shipped Not Invoiced';

        }
        field(60; "Quantity Shipped"; Decimal)
        {

            Caption = 'Quantity Shipped';

        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';

        }
        field(63; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';

        }
        field(64; "Shipment Line No."; Integer)
        {
            Caption = 'Shipment Line No.';
            Editable = false;
        }
        field(67; "Profit %"; Decimal)
        {
            Caption = 'Profit %';

            Editable = false;
        }
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;

        }
        field(69; "Inv. Discount Amount"; Decimal)
        {

        }
        field(71; "Purchase Order No."; Code[20])
        {

        }
        field(72; "Purch. Order Line No."; Integer)
        {

        }
        field(73; "Drop Shipment"; Boolean)
        {

        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                GenBusPostingGrp: Record "Gen. Business Posting Group";
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;

        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                GenProdPostingGrp: Record "Gen. Product Posting Group";
            begin
                TestJobPlanningLine();
                TestStatusOpen();
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;

        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;

        }
        field(81; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(82; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(84; "Tax Category"; Code[10])
        {
            Caption = 'Tax Category';
        }
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";



        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            Editable = false;


        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';

        }
        field(88; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                ValidateVATProdPostingGroup();
            end;

        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
                VATPostingSetup: Record "VAT Posting Setup";
                SalesHeader: Record "Customer Header";
                Currency: Record Currency;
            begin
                VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                "VAT Difference" := 0;
                GetSalesHeader();
                "VAT %" := VATPostingSetup."VAT %";
                "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                    Validate("Allow Invoice Disc.", false);
                "VAT Identifier" := VATPostingSetup."VAT Identifier";
                "VAT Clause Code" := VATPostingSetup."VAT Clause Code";

                IsHandled := false;
                OnValidateVATProdPostingGroupOnBeforeCheckVATCalcType(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    case "VAT Calculation Type" of
                        "VAT Calculation Type"::"Reverse Charge VAT",
                        "VAT Calculation Type"::"Sales Tax":
                            "VAT %" := 0;
                        "VAT Calculation Type"::"Full VAT":
                            begin
                                TestField(Type, Type::"G/L Account");
                                TestField("No.", VATPostingSetup.GetSalesAccount(false));
                            end;
                    end;

                IsHandled := FALSE;
                OnValidateVATProdPostingGroupOnBeforeUpdateUnitPrice(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    if SalesHeader."Prices Including VAT" and (Type in [Type::Item, Type::Resource]) then
                        Validate("Unit Price",
                            Round(
                                "Unit Price" * (100 + "VAT %") / (100 + xRec."VAT %"),
                        Currency."Unit-Amount Rounding Precision"));

                OnValidateVATProdPostingGroupOnBeforeUpdateAmounts(Rec, xRec, SalesHeader, Currency);
            end;
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(92; "Outstanding Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Outstanding Amount (LCY)';
            Editable = false;
        }
        field(93; "Shipped Not Invoiced (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced (LCY) Incl. VAT';
            Editable = false;
        }
        field(94; "Shipped Not Inv. (LCY) No VAT"; Decimal)
        {
            Caption = 'Shipped Not Invoiced (LCY)';
            Editable = false;
            FieldClass = Normal;
        }
        field(95; "Reserved Quantity"; Decimal)
        {

        }
        field(96; Reserve; Enum "Reserve Method")
        {

        }
        field(97; "Blanket Order No."; Code[20])
        {

        }
        field(98; "Blanket Order Line No."; Integer)
        {


        }
        field(99; "VAT Base Amount"; Decimal)
        {

        }
        field(100; "Unit Cost"; Decimal)
        {

        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(103; "Line Amount"; Decimal)
        {
            trigger OnValidate()
            var
                MaxLineAmount: Decimal;
                IsHandled: Boolean;
                Currency: Record Currency;
            begin
                IsHandled := false;
                OnBeforeValidateLineAmount(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField(Type);
                TestField(Quantity);
                IsHandled := false;
                OnValidateLineAmountOnbeforeTestUnitPrice(Rec, IsHandled);
                if not IsHandled then
                    TestField("Unit Price");

                "Line Amount" := Round("Line Amount", Currency."Amount Rounding Precision");
                MaxLineAmount := Round(Quantity * "Unit Price", Currency."Amount Rounding Precision");


                Validate("Line Discount Amount", MaxLineAmount - "Line Amount");
            end;
        }
        field(104; "VAT Difference"; Decimal)
        {

        }
        field(105; "Inv. Disc. Amount to Invoice"; Decimal)
        {

        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';

        }
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {

        }
        field(108; "IC Partner Reference"; Code[20])
        {

        }
        field(109; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';


        }
        field(110; "Prepmt. Line Amount"; Decimal)
        {

        }
        field(111; "Prepmt. Amt. Inv."; Decimal)
        {

        }
        field(112; "Prepmt. Amt. Incl. VAT"; Decimal)
        {

        }
        field(113; "Prepayment Amount"; Decimal)
        {

        }
        field(114; "Prepmt. VAT Base Amt."; Decimal)
        {

        }
        field(115; "Prepayment VAT %"; Decimal)
        {
            Caption = 'Prepayment VAT %';

        }
        field(116; "Prepmt. VAT Calc. Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Prepmt. VAT Calc. Type';

        }
        field(117; "Prepayment VAT Identifier"; Code[20])
        {
            Caption = 'Prepayment VAT Identifier';

        }
        field(118; "Prepayment Tax Area Code"; Code[20])
        {
            Caption = 'Prepayment Tax Area Code';

        }
        field(119; "Prepayment Tax Liable"; Boolean)
        {
            Caption = 'Prepayment Tax Liable';


        }
        field(120; "Prepayment Tax Group Code"; Code[20])
        {
            Caption = 'Prepayment Tax Group Code';

        }
        field(121; "Prepmt Amt to Deduct"; Decimal)
        {

        }
        field(122; "Prepmt Amt Deducted"; Decimal)
        {

        }
        field(123; "Prepayment Line"; Boolean)
        {
            Caption = 'Prepayment Line';

        }
        field(124; "Prepmt. Amount Inv. Incl. VAT"; Decimal)
        {

        }
        field(129; "Prepmt. Amount Inv. (LCY)"; Decimal)
        {

            Caption = 'Prepmt. Amount Inv. (LCY)';

        }
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';

        }
        field(132; "Prepmt. VAT Amount Inv. (LCY)"; Decimal)
        {
            Caption = 'Prepmt. VAT Amount Inv. (LCY)';

        }
        field(135; "Prepayment VAT Difference"; Decimal)
        {

        }
        field(136; "Prepmt VAT Diff. to Deduct"; Decimal)
        {

        }
        field(137; "Prepmt VAT Diff. Deducted"; Decimal)
        {

        }
        field(138; "IC Item Reference No."; Code[50])
        {

        }
        field(145; "Pmt. Discount Amount"; Decimal)
        {

        }
        field(180; "Line Discount Calculation"; Option)
        {
            Caption = 'Line Discount Calculation';
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';

        }
        field(900; "Qty. to Assemble to Order"; Decimal)
        {

        }
        field(901; "Qty. to Asm. to Order (Base)"; Decimal)
        {
            Caption = 'Qty. to Asm. to Order (Base)';

        }
        field(902; "ATO Whse. Outstanding Qty."; Decimal)
        {

            Caption = 'ATO Whse. Outstanding Qty.';

        }
        field(903; "ATO Whse. Outstd. Qty. (Base)"; Decimal)
        {

            Caption = 'ATO Whse. Outstd. Qty. (Base)';

        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';

        }
        field(1002; "Job Contract Entry No."; Integer)
        {

        }
        field(1300; "Posting Date"; Date)
        {

        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';

        }
        field(1702; "Returns Deferral Start Date"; Date)
        {
            Caption = 'Returns Deferral Start Date';


        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';



        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';



        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';

        }
        field(5405; Planned; Boolean)
        {
            Caption = 'Planned';
            Editable = false;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';

        }
        field(5415; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestJobPlanningLine();
                TestField("Qty. per Unit of Measure", 1);
                if "Quantity (Base)" <> xRec."Quantity (Base)" then
                    PlanPriceCalcByField(FieldNo("Quantity (Base)"));
                Validate(Quantity, "Quantity (Base)");
                UpdateUnitPriceByField(FieldNo("Quantity (Base)"));
            end;


        }
        field(5416; "Outstanding Qty. (Base)"; Decimal)
        {
            Caption = 'Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5417; "Qty. to Invoice (Base)"; Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Invoice", "Qty. to Invoice (Base)");
            end;

        }
        field(5418; "Qty. to Ship (Base)"; Decimal)
        {
            Caption = 'Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Ship", "Qty. to Ship (Base)");
            end;

        }
        field(5458; "Qty. Shipped Not Invd. (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invd. (Base)';

        }
        field(5460; "Qty. Shipped (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped (Base)';

        }
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';

        }
        field(5495; "Reserved Qty. (Base)"; Decimal)
        {

            Caption = 'Reserved Qty. (Base)';

        }
        field(5600; "FA Posting Date"; Date)
        {

            Caption = 'FA Posting Date';
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';

        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {

            Caption = 'Depr. until FA Posting Date';
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';

        }
        field(5613; "Use Duplication List"; Boolean)
        {

        }
        field(5700; "Responsibility Center"; Code[10])
        {

        }
        field(5701; "Out-of-Stock Substitution"; Boolean)
        {
            Caption = 'Out-of-Stock Substitution';

        }
        field(5702; "Substitution Available"; Boolean)
        {

        }
        field(5703; "Originally Ordered No."; Code[20])
        {

        }
        field(5704; "Originally Ordered Var. Code"; Code[10])
        {
        }
        field(5705; "Cross-Reference No."; Code[20])
        {
            AccessByPermission = TableData "Item Cross Reference" = R;
            Caption = 'Cross-Reference No.';

        }
        field(5706; "Unit of Measure (Cross Ref.)"; Code[10])
        {

            Caption = 'Unit of Measure (Cross Ref.)';

        }
        field(5707; "Cross-Reference Type"; Option)
        {
            Caption = 'Cross-Reference Type';
            OptionCaption = ' ,Customer,Vendor,Bar Code';
            OptionMembers = " ",Customer,Vendor,"Bar Code";

        }
        field(5708; "Cross-Reference Type No."; Code[30])
        {
            Caption = 'Cross-Reference Type No.';

        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';

        }
        field(5710; Nonstock; Boolean)
        {

            Caption = 'Catalog';

        }
        field(5711; "Purchasing Code"; Code[10])
        {

            Caption = 'Purchasing Code';

        }
        field(5712; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';

        }
        field(5713; "Special Order"; Boolean)
        {

        }
        field(5714; "Special Order Purchase No."; Code[20])
        {
        }

        field(5715; "Special Order Purch. Line No."; Integer)
        {

        }
        field(5725; "Item Reference No."; Code[50])
        {

            Caption = 'Item Reference No.';


        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {

            Caption = 'Reference Unit of Measure';

        }
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
        }
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
        }
        field(5749; "Whse. Outstanding Qty."; Decimal)
        {

            Caption = 'Whse. Outstanding Qty.';

        }
        field(5750; "Whse. Outstanding Qty. (Base)"; Decimal)
        {

            Caption = 'Whse. Outstanding Qty. (Base)';

        }
        field(5752; "Completely Shipped"; Boolean)
        {
            Caption = 'Completely Shipped';
            Editable = false;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';


        }
        field(5791; "Promised Delivery Date"; Date)
        {

            Caption = 'Promised Delivery Date';


        }
        field(5792; "Shipping Time"; DateFormula)
        {

            Caption = 'Shipping Time';


        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {

            Caption = 'Outbound Whse. Handling Time';


        }
        field(5794; "Planned Delivery Date"; Date)
        {

            Caption = 'Planned Delivery Date';


        }
        field(5795; "Planned Shipment Date"; Date)
        {
            Caption = 'Planned Shipment Date';


        }
        field(5796; "Shipping Agent Code"; Code[10])
        {

            Caption = 'Shipping Agent Code';

        }
        field(5797; "Shipping Agent Service Code"; Code[10])
        {

            Caption = 'Shipping Agent Service Code';

        }
        field(5800; "Allow Item Charge Assignment"; Boolean)
        {

            Caption = 'Allow Item Charge Assignment';

        }
        field(5801; "Qty. to Assign"; Decimal)
        {


        }
        field(5802; "Qty. Assigned"; Decimal)
        {

            Caption = 'Qty. Assigned';

        }
        field(5803; "Return Qty. to Receive"; Decimal)
        {

            Caption = 'Return Qty. to Receive';

        }
        field(5804; "Return Qty. to Receive (Base)"; Decimal)
        {
            Caption = 'Return Qty. to Receive (Base)';

        }
        field(5805; "Return Qty. Rcd. Not Invd."; Decimal)
        {
            Caption = 'Return Qty. Rcd. Not Invd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5806; "Ret. Qty. Rcd. Not Invd.(Base)"; Decimal)
        {
            Caption = 'Ret. Qty. Rcd. Not Invd.(Base)';

        }
        field(5807; "Return Rcd. Not Invd."; Decimal)
        {

            Caption = 'Return Rcd. Not Invd.';

        }
        field(5808; "Return Rcd. Not Invd. (LCY)"; Decimal)
        {

            Caption = 'Return Rcd. Not Invd. (LCY)';
            Editable = false;
        }
        field(5809; "Return Qty. Received"; Decimal)
        {

        }
        field(5810; "Return Qty. Received (Base)"; Decimal)
        {
            Caption = 'Return Qty. Received (Base)';

        }
        field(5811; "Appl.-from Item Entry"; Integer)
        {

        }
        field(5909; "BOM Item No."; Code[20])
        {
            Caption = 'BOM Item No.';
            TableRelation = Item;
        }
        field(6600; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
            Editable = false;
        }
        field(6601; "Return Receipt Line No."; Integer)
        {
            Caption = 'Return Receipt Line No.';
            Editable = false;
        }
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';

        }
        field(6610; "Copied From Posted Doc."; Boolean)
        {
            Caption = 'Copied From Posted Doc.';
            DataClassification = SystemMetadata;
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
        }
        field(7002; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';

        }
        field(7003; Subtype; Option)
        {
            Caption = 'Subtype';
            OptionCaption = ' ,Item - Inventory,Item - Service,Comment';
            OptionMembers = " ","Item - Inventory","Item - Service",Comment;

        }
        field(7004; "Price description"; Text[80])
        {
            Caption = 'Price description';
        }
        field(7010; "Attached Doc Count"; Integer)
        {
            Caption = 'Attached Doc Count';
        }
        field(10000; "Package Tracking No."; Text[30])
        {
            Caption = 'Package Tracking No.';
        }

    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Line No.", "Document Type")
        {
            Enabled = false;
        }
        key(Key3; "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date")
        {
            SumIndexFields = "Outstanding Qty. (Base)";
        }
        key(Key4; "Document Type", "Bill-to Customer No.", "Currency Code", "Document No.")
        {
            SumIndexFields = "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)", "Return Rcd. Not Invd. (LCY)";
        }
        key(Key5; "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Location Code", "Shipment Date")
        {
            Enabled = false;
            SumIndexFields = "Outstanding Qty. (Base)";
        }
        key(Key6; "Document Type", "Bill-to Customer No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Currency Code", "Document No.")
        {
            Enabled = false;
            SumIndexFields = "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)";
        }
        key(Key7; "Document Type", "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key8; "Document Type", "Document No.", "Location Code")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "Amount Including VAT", "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)";
        }
        key(Key9; "Document Type", "Shipment No.", "Shipment Line No.")
        {
        }
        key(Key10; Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Document Type", "Shipment Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key11; "Document Type", "Sell-to Customer No.", "Shipment No.", "Document No.")
        {
            SumIndexFields = "Outstanding Amount (LCY)";
        }
        key(Key12; "Job Contract Entry No.")
        {
        }
        key(Key13; "Document Type", "Document No.", "Qty. Shipped Not Invoiced")
        {
            Enabled = false;
        }
        key(Key14; "Document Type", "Document No.", Type, "No.")
        {
            Enabled = false;
        }

    }


    [IntegrationEvent(false, false)]
    local procedure OnAfterIsCreditDocType(SalesLine: Record "Customer Line"; var CreditDocType: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesSetup(var SalesLine: Record "Customer Line"; var SalesSetup: Record "Sales & Receivables Setup")
    begin
    end;


    local procedure ValidateVATProdPostingGroup()
    var
        IsHandled: boolean;
    begin
        IsHandled := false;
        OnBeforeValidateVATProdPostingGroup(IsHandled);
        if IsHandled then
            exit;

        Validate("VAT Prod. Posting Group");
    end;

    procedure GetSalesHeader()
    var
        SalesHeader: Record "Customer Header";
        Currency: Record Currency;
    begin
        GetSalesHeader(SalesHeader, Currency);
    end;

    procedure GetSalesHeader(var OutSalesHeader: Record "Customer Header"; var OutCurrency: Record Currency)
    var
        IsHandled: Boolean;
        SalesHeader: Record "Customer Header";
        Currency: Record Currency;
    begin
        OnBeforeGetSalesHeader(Rec, SalesHeader, IsHandled, Currency);
        if IsHandled then
            exit;

        TestField("Document No.");
        if ("Document Type" <> SalesHeader."Document Type") or ("Document No." <> SalesHeader."No.") then begin
            SalesHeader.Get("Document Type", "Document No.");
            if SalesHeader."Currency Code" = '' then
                Currency.InitRoundingPrecision
            else begin
                SalesHeader.TestField("Currency Factor");
                Currency.Get(SalesHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;

        OnAfterGetSalesHeader(Rec, SalesHeader, Currency);
        OutSalesHeader := SalesHeader;
        OutCurrency := Currency;
    end;

    procedure InitOutstandingAmount()
    var
        AmountInclVAT: Decimal;
        IsHandled: Boolean;
        Currency: Record Currency;
        SalesHeader: Record "Customer Header";
    begin
        IsHandled := false;
        OnBeforeInitOutstandingAmount(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Quantity = 0 then begin
            "Outstanding Amount" := 0;
            "Outstanding Amount (LCY)" := 0;
            "Shipped Not Invoiced" := 0;
            "Shipped Not Invoiced (LCY)" := 0;
            "Return Rcd. Not Invd." := 0;
            "Return Rcd. Not Invd. (LCY)" := 0;
        end else begin
            GetSalesHeader();
            AmountInclVAT := "Amount Including VAT";
            Validate(
              "Outstanding Amount",
              Round(
                AmountInclVAT * "Outstanding Quantity" / Quantity,
                Currency."Amount Rounding Precision"));
            if IsCreditDocType() then
                Validate(
                  "Return Rcd. Not Invd.",
                  Round(
                    AmountInclVAT * "Return Qty. Rcd. Not Invd." / Quantity,
                    Currency."Amount Rounding Precision"))
            else
                Validate(
                  "Shipped Not Invoiced",
                  Round(
                    AmountInclVAT * "Qty. Shipped Not Invoiced" / Quantity,
                    Currency."Amount Rounding Precision"));
        end;

        OnAfterInitOutstandingAmount(Rec, SalesHeader, Currency);
    end;

    procedure IsCreditDocType() CreditDocType: Boolean
    begin
        CreditDocType := "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"];
        OnAfterIsCreditDocType(Rec, CreditDocType);
    end;

    local procedure UpdateVATPercent(BaseAmount: Decimal; VATAmount: Decimal)
    begin
        if BaseAmount <> 0 then
            "VAT %" := Round(100 * VATAmount / BaseAmount, 0.00001)
        else
            "VAT %" := 0;
    end;


    var
        GlobalSalesHeader: Record "Sales Header";
        GlobalField: Record "Field";


    local procedure GetSalesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        SalesSetupRead: Boolean;
    begin
        if not SalesSetupRead then
            SalesSetup.Get();
        SalesSetupRead := true;
        OnAfterGetSalesSetup(Rec, SalesSetup);
    end;


    local procedure TestJobPlanningLine()
    var
        JobPostLine: Codeunit "Job Post-Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestJobPlanningLine(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if "Job Contract Entry No." = 0 then
            exit;
        TestSalesLine(Rec);
    end;


    procedure TestSalesLine(var SalesLine: Record "Customer Line")
    var
        JT: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Txt: Text[250];
        Text003: Label 'You cannot change the sales line because it is linked to\';
        Text004: Label ' %1: %2= %3, %4= %5.';
    begin
        if SalesLine."Job Contract Entry No." = 0 then
            exit;
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
        if JobPlanningLine.FindFirst then begin
            JT.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
            Txt := Text003 + StrSubstNo(Text004,
                JT.TableCaption, JT.FieldCaption("Job No."), JT."Job No.",
                JT.FieldCaption("Job Task No."), JT."Job Task No.");
            Error(Txt);
        end;
    end;

    procedure HasTypeToFillMandatoryFields() ReturnValue: Boolean
    begin
        ReturnValue := Type <> Type::" ";

        OnAfterHasTypeToFillMandatoryFields(Rec, ReturnValue);
    end;

    local procedure InitHeaderDefaults(SalesHeader: Record "Customer Header")
    Var
        Text031: Label 'You must either specify %1 or %2.';
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then begin
            "Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
            "Currency Code" := SalesHeader."Currency Code";
            InitHeaderLocactionCode(SalesHeader);
            "Customer Price Group" := SalesHeader."Customer Price Group";
            "Customer Disc. Group" := SalesHeader."Customer Disc. Group";
            "Allow Line Disc." := SalesHeader."Allow Line Disc.";
            "Transaction Type" := SalesHeader."Transaction Type";
            "Transport Method" := SalesHeader."Transport Method";
            "Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
            "Price Calculation Method" := SalesHeader."Price Calculation Method";
            "Gen. Bus. Posting Group" := SalesHeader."Gen. Bus. Posting Group";
            "VAT Bus. Posting Group" := SalesHeader."VAT Bus. Posting Group";
            "Exit Point" := SalesHeader."Exit Point";
            Area := SalesHeader.Area;
            "Transaction Specification" := SalesHeader."Transaction Specification";
            "Tax Area Code" := SalesHeader."Tax Area Code";
            "Tax Liable" := SalesHeader."Tax Liable";
            if not "System-Created Entry" and ("Document Type" = "Document Type"::Order) and HasTypeToFillMandatoryFields() or
               IsServiceChargeLine()
            then
                "Prepayment %" := SalesHeader."Prepayment %";
            "Prepayment Tax Area Code" := SalesHeader."Tax Area Code";
            "Prepayment Tax Liable" := SalesHeader."Tax Liable";
            "Responsibility Center" := SalesHeader."Responsibility Center";

            "Shipping Agent Code" := SalesHeader."Shipping Agent Code";
            "Shipping Agent Service Code" := SalesHeader."Shipping Agent Service Code";
            "Outbound Whse. Handling Time" := SalesHeader."Outbound Whse. Handling Time";
            "Shipping Time" := SalesHeader."Shipping Time";

            OnAfterInitHeaderDefaults(Rec, SalesHeader, xRec);
        end;
    End;

    local procedure InitHeaderLocactionCode(SalesHeader: Record "Customer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitHeaderLocactionCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if not IsNonInventoriableItem then
            "Location Code" := SalesHeader."Location Code";
    end;

    procedure IsServiceChargeLine(): Boolean
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Customer Header";
    begin
        if Type <> Type::"G/L Account" then
            exit(false);

        GetSalesHeader();
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        exit(CustomerPostingGroup."Service Charge Acc." = "No.");
    end;

    procedure GetItem(var Item: Record Item)
    begin
        TestField("No.");
        Item.Get("No.");
    end;

    procedure PlanPriceCalcByField(CurrPriceFieldNo: Integer)
    FieldCausedPriceCalculation: Integer;
    begin
        if FieldCausedPriceCalculation = 0 then
            FieldCausedPriceCalculation := CurrPriceFieldNo;
    end;

    procedure IsNonInventoriableItem(): Boolean
    var
        Item: Record Item;
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItem(Item);
        exit(Item.IsNonInventoriableType());
    end;

    local procedure UpdateUnitPriceByField(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
        PriceCalculation: Interface "Price Calculation";
        SalesHeader: Record "Customer Header";
        PriceType: Enum "Price Type";
        UnitPriceChangedMsg: Label 'The unit price for %1 %2 that was copied from the posted document has been changed.', Comment = '%1 = Type caption %2 = No.';
    begin
        if not IsPriceCalcCalledByField(CalledByFieldNo) then
            exit;

        IsHandled := false;
        OnBeforeUpdateUnitPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetSalesHeader();
        TestField("Qty. per Unit of Measure");

        case Type of
            Type::"G/L Account",
            Type::Item,
            Type::Resource:
                begin
                    IsHandled := false;
                    OnUpdateUnitPriceOnBeforeFindPrice(SalesHeader, Rec, CalledByFieldNo, CurrFieldNo, IsHandled);
                    if not IsHandled then begin
                        GetPriceCalculationHandler(PriceType::Sale, SalesHeader, PriceCalculation);
                        if not ("Copied From Posted Doc." and IsCreditDocType()) then begin
                            PriceCalculation.ApplyDiscount();
                            ApplyPrice(CalledByFieldNo, PriceCalculation);
                        end;
                    end;
                    OnUpdateUnitPriceByFieldOnAfterFindPrice(SalesHeader, Rec, CalledByFieldNo, CurrFieldNo);
                end;
        end;

        if "Copied From Posted Doc." and IsCreditDocType() and ("Appl.-from Item Entry" <> 0) then
            if xRec."Unit Price" <> "Unit Price" then
                if GuiAllowed then
                    ShowMessageOnce(StrSubstNo(UnitPriceChangedMsg, Type, "No."));

        Validate("Unit Price");

        ClearFieldCausedPriceCalculation();
        OnAfterUpdateUnitPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo);
    end;

    procedure ClearFieldCausedPriceCalculation()
    var
        FieldCausedPriceCalculation: Integer;
    begin
        FieldCausedPriceCalculation := 0;
    end;

    local procedure UpdateQuantityFromUOMCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQuantityFromUOMCode(Rec, IsHandled);
        if IsHandled then
            exit;

        Validate(Quantity);
    end;

    procedure ApplyPrice(CalledByFieldNo: Integer; var PriceCalculation: Interface "Price Calculation")
    begin
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        GetLineWithCalculatedPrice(PriceCalculation);
        OnAfterApplyPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo);
    end;

    procedure IsPriceCalcCalledByField(CurrPriceFieldNo: Integer): Boolean;
    var
        FieldCausedPriceCalculation: Integer;
    begin
        exit(FieldCausedPriceCalculation = CurrPriceFieldNo);
    end;


    local procedure ShowMessageOnce(MessageText: Text)
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        TempErrorMessage.SetContext(Rec);
        if TempErrorMessage.FindRecord(RecordId, 0, TempErrorMessage."Message Type"::Warning, MessageText) = 0 then begin
            TempErrorMessage.LogMessage(Rec, 0, TempErrorMessage."Message Type"::Warning, MessageText);
            Message(MessageText);
        end;
    end;

    local procedure GetLineWithCalculatedPrice(var PriceCalculation: Interface "Price Calculation")
    var
        Line: Variant;
    begin
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    local procedure GetPriceCalculationHandler(PriceType: Enum "Price Type"; SalesHeader: Record "Customer Header"; var PriceCalculation: Interface "Price Calculation")
    var
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        if (SalesHeader."No." = '') and ("Document No." <> '') then
            SalesHeader.Get("Document Type", "Document No.");
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType, SalesHeader, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
    end;

    Protected var
        StatusCheckSuspended: Boolean;

    procedure TestStatusOpen()
    var
        IsHandled: Boolean;
        SalesHeader: Record "Customer Header";
    begin
        GetSalesHeader();
        IsHandled := false;
        OnBeforeTestStatusOpen(Rec, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if StatusCheckSuspended then
            exit;

        if not "System-Created Entry" then
            if (xRec.Type <> Type) or HasTypeToFillMandatoryFields() then
                SalesHeader.TestField(Status, SalesHeader.Status::Open);

        OnAfterTestStatusOpen(Rec, SalesHeader);
    end;

    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        LineWithPrice := SalesLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    procedure MaxQtyToInvoice(): Decimal
    var
        MaxQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMaxQtyToInvoice(Rec, MaxQty, IsHandled);
        if IsHandled then
            exit(MaxQty);

        if "Prepayment Line" then
            exit(1);

        if IsCreditDocType() then
            exit("Return Qty. Received" + "Return Qty. to Receive" - "Quantity Invoiced");

        exit("Quantity Shipped" + "Qty. to Ship" - "Quantity Invoiced");
    end;

    procedure MaxQtyToInvoiceBase(): Decimal
    var
        MaxQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMaxQtyToInvoiceBase(Rec, MaxQtyBase, IsHandled);
        if IsHandled then
            exit(MaxQtyBase);

        if IsCreditDocType() then
            exit("Return Qty. Received (Base)" + "Return Qty. to Receive (Base)" - "Qty. Invoiced (Base)");

        exit("Qty. Shipped (Base)" + "Qty. to Ship (Base)" - "Qty. Invoiced (Base)");
    end;

    local procedure UpdateQtyToAsmFromSalesLineQtyToShip()
    var
        IsHandled: Boolean;
        ATOLink: Record "Assemble-to-Order Link";
    begin
        IsHandled := false;
        OnBeforeUpdateQtyToAsmFromSalesLineQtyToShip(Rec, IsHandled);
        if IsHandled then
            exit;
    end;



    procedure InitOutstanding()
    begin
        if IsCreditDocType() then begin
            "Outstanding Quantity" := Quantity - "Return Qty. Received";
            "Outstanding Qty. (Base)" := "Quantity (Base)" - "Return Qty. Received (Base)";
            "Return Qty. Rcd. Not Invd." := "Return Qty. Received" - "Quantity Invoiced";
            "Ret. Qty. Rcd. Not Invd.(Base)" := "Return Qty. Received (Base)" - "Qty. Invoiced (Base)";
        end else begin
            "Outstanding Quantity" := Quantity - "Quantity Shipped";
            "Outstanding Qty. (Base)" := "Quantity (Base)" - "Qty. Shipped (Base)";
            "Qty. Shipped Not Invoiced" := "Quantity Shipped" - "Quantity Invoiced";
            "Qty. Shipped Not Invd. (Base)" := "Qty. Shipped (Base)" - "Qty. Invoiced (Base)";
        end;
        OnAfterInitOutstandingQty(Rec);
        "Completely Shipped" := (Quantity <> 0) and ("Outstanding Quantity" = 0);
        InitOutstandingAmount();

        OnAfterInitOutstanding(Rec);
    end;

    procedure InitQtyToReceive()
    Var
        salesSetup: Record "Sales & Receivables Setup";
        UOMMgt: Codeunit "Unit of Measure Management";

    begin
        GetSalesSetup();
        if (SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Remainder) or
           ("Document Type" = "Document Type"::"Credit Memo")
        then begin
            "Return Qty. to Receive" := "Outstanding Quantity";
            "Return Qty. to Receive (Base)" := "Outstanding Qty. (Base)";
        end else
            if "Return Qty. to Receive" <> 0 then
                "Return Qty. to Receive (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Return Qty. to Receive", "Qty. per Unit of Measure");

        OnAfterInitQtyToReceive(Rec, CurrFieldNo);
        InitQtyToInvoice();
    end;

    procedure InitQtyToShip()
    Var
        salesSetup: Record "Sales & Receivables Setup";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        GetSalesSetup();
        if (SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Remainder) or
           ("Document Type" = "Document Type"::Invoice)
        then begin
            "Qty. to Ship" := "Outstanding Quantity";
            "Qty. to Ship (Base)" := "Outstanding Qty. (Base)";
        end else
            if "Qty. to Ship" <> 0 then
                "Qty. to Ship (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. to Ship", "Qty. per Unit of Measure");

        OnInitQtyToShipOnBeforeCheckServItemCreation(Rec);
        CheckServItemCreation();
        OnAfterInitQtyToShip(Rec, CurrFieldNo);

        InitQtyToInvoice();
    end;

    procedure CheckServItemCreation()
    var
        Item: Record Item;
        ServItemGroup: Record "Service Item Group";
        Text034: Label 'The value of %1 field must be a whole number for the item included in the service item group if the %2 field in the Service Item Groups window contains a check mark.';
    begin
        if CurrFieldNo = 0 then
            exit;
        if Type <> Type::Item then
            exit;
        GetItem(Item);
        if Item."Service Item Group" = '' then
            exit;
        if ServItemGroup.Get(Item."Service Item Group") then
            if ServItemGroup."Create Service Item" then
                if "Qty. to Ship (Base)" <> Round("Qty. to Ship (Base)", 1) then
                    Error(
                      Text034,
                      FieldCaption("Qty. to Ship (Base)"),
                      ServItemGroup.FieldCaption("Create Service Item"));
    end;

    procedure InitQtyToInvoice()
    begin
        "Qty. to Invoice" := MaxQtyToInvoice;
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase;
        "VAT Difference" := 0;
        OnBeforeCalcInvDiscToInvoice(Rec, CurrFieldNo);
        OnAfterInitQtyToInvoice(Rec, CurrFieldNo);
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Customer Line", "Document Type".AsInteger(), "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', 0);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; SalesLine: Record "Customer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToReceive(var SalesLine: Record "Customer Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitQtyToShipOnBeforeCheckServItemCreation(var SalesLine: Record "Customer Line")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var SalesLine: Record "Customer Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscToInvoice(var SalesLine: Record "Customer Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToInvoice(var SalesLine: Record "Customer Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstanding(var SalesLine: Record "Customer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingQty(var SalesLine: Record "Customer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMaxQtyToInvoice(SalesLine: Record "Customer Line"; var MaxQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMaxQtyToInvoiceBase(SalesLine: Record "Customer Line"; var MaxQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatusOpen(var SalesLine: Record "Customer Line"; var SalesHeader: Record "CUstomer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestStatusOpen(var SalesLine: Record "Customer Line"; var SalesHeader: Record "Customer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQuantityFromUOMCode(var SalesLine: Record "Customer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyPrice(var SalesLine: Record "Customer Line"; var xSalesLine: Record "Customer Line"; CallFieldNo: Integer; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitPrice(var SalesLine: Record "Customer Line"; xSalesLine: Record "Customer Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitPrice(var SalesLine: Record "Customer Line"; xSalesLine: Record "Customer Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitPriceOnBeforeFindPrice(SalesHeader: Record "CUstomer Header"; var SalesLine: Record "CUstomer Line"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitHeaderLocactionCode(var SalesLine: Record "Customer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitHeaderDefaults(var SalesLine: Record "Customer Line"; SalesHeader: Record "Customer Header"; xSalesLine: Record "Customer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeInitHeaderDefaults(SalesHeader: Record "Customer Header"; var SalesLine: Record "Customer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterInitHeaderDefaults(var SalesHeader: Record "Customer Header"; var TempSalesLine: Record "Customer Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasTypeToFillMandatoryFields(var SalesLine: Record "Customer Line"; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestJobPlanningLine(var SalesLine: Record "Customer Line"; var IsHandled: Boolean; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitOutstandingAmount(var SalesLine: Record "Customer Line"; xSalesLine: Record "Customer Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingAmount(var SalesLine: Record "Customer Line"; SalesHeader: Record "Customer Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesHeader(var SalesLine: Record "Customer Line"; var SalesHeader: Record "Customer Header"; var IsHanded: Boolean; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesHeader(var SalesLine: Record "Customer Line"; var SalesHeader: Record "Customer Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateVATProdPostingGroup(var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLineAmountOnbeforeTestUnitPrice(var SalesLine: Record "Customer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineAmount(var SalesLine: Record "Customer Line"; xSalesLine: Record "Customer Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeCheckVATCalcType(var SalesLine: Record "Customer Line"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeUpdateUnitPrice(var SalesLine: Record "Customer Line"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeUpdateAmounts(var SalesLine: Record "Customer Line"; xSalesLine: Record "Customer Line"; SalesHeader: Record "Customer Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculate(var SalesLine: Record "Customer Line"; SalesHeader: Record "Customer Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateReverse(var SalesLine: Record "Customer Line"; SalesHeader: Record "Customer Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountIncludingVATOnAfterAssignAmounts(var SalesLine: Record "Customer Line"; Currency: Record Currency);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitPriceByFieldOnAfterFindPrice(SalesHeader: Record "Customer Header"; var SalesLine: Record "Customer Line"; CalledByFieldNo: Integer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToShipAfterInitQty(var SalesLine: Record "Customer Line"; var xSalesLine: Record "Customer Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQtyToAsmFromSalesLineQtyToShip(var SalesLine: Record "Customer Line"; var IsHandled: Boolean)
    begin
    end;
}

