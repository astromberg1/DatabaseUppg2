--• Lista alla order och dess attribut som inte är nycklar, samt kund och de produkter som ingår i ordern, 
--samt vilket fraktbolag ska skeppa ordern.

use DBuppg2

IF OBJECT_ID (N'spVisaAllaOrdrar', N'P') IS NOT NULL
    DROP PROC spVisaAllaOrdrar;
GO
CREATE PROC spVisaAllaOrdrar
AS
SELECT * FROM ViewAllaDelordrar ORDER BY ViewAllaDelordrar.OrderNummer ASC
GO

EXEC spVisaAllaOrdrar

----Lista alla order som en kund (Kunden ska kunna sökas med delar av efternamnet) har och de produkter som ingår i ordern, 
----samt vilket fraktbolag ska skeppa ordern.

IF OBJECT_ID (N'spVisaAllaKundordrar', N'P') IS NOT NULL
    DROP PROC spVisaAllaKundordrar;
GO

CREATE PROC spVisaAllaKundordrar
(
@KundDelEfterNamn nvarchar(50) ='Kul'
)
AS
SELECT * FROM ViewAllaDelordrar WHERE ViewAllaDelordrar.KundEfterNamn LIKE '%'+@KundDelEfterNamn+'%'
GO

EXEC spVisaAllaKundordrar 'Kul'



----Visa den order med mest produkter i.
IF OBJECT_ID (N'spVisaOrderMedMestProdukter', N'P') IS NOT NULL
    DROP PROC spVisaOrderMedMestProdukter;
GO
CREATE PROC spVisaOrderMedMestProdukter
AS
SELECT * FROM ViewOrdrar WHERE ViewOrdrar.SummaAntal= (SELECT MAX(ViewOrdrar.SummaAntal) FROM ViewOrdrar)
GO

EXEC spVisaOrderMedMestProdukter

----Visa den dyraste ordern i systemet och kundens namn.

IF OBJECT_ID (N'spVisaDyrasteOrdern', N'P') IS NOT NULL
    DROP PROC spVisaDyrasteOrdern;
GO
CREATE PROC spVisaDyrasteOrdern
AS
SELECT * FROM ViewOrdrar WHERE ViewOrdrar.TotalorderBelopp= (SELECT MAX(ViewOrdrar.TotalorderBelopp) FROM ViewOrdrar)
GO

EXEC spVisaDyrasteOrdern

--Visa alla order som ett fraktbolag skeppar. Ska kunna sökas med namnet på fraktbolaget.
IF OBJECT_ID (N'spVisaOrdrarFraktbolag', N'P') IS NOT NULL
    DROP PROC spVisaOrdrarFraktbolag;
GO
CREATE PROC spVisaOrdrarFraktbolag
(
@Fraktbolaget nvarchar(50) ='akkafrakt'
)
AS
SELECT * FROM ViewOrdrar WHERE ViewOrdrar.FraktbolagsNamn = @Fraktbolaget
GO

EXEC spVisaOrdrarFraktbolag 'akkafrakt'

----Visa alla order som ska skeppas på ett viss datum och fraktbolaget. Ska sökas med ett datum.
IF OBJECT_ID (N'spVisaOrdrarDatum', N'P') IS NOT NULL
    DROP PROC spVisaOrdrarDatum;
GO
CREATE PROC spVisaOrdrarDatum
(
@Skeppdatum date = '2016-04-14'
)
AS
--SELECT * FROM ViewOrdrar WHERE ViewOrdrar.FraktbolagsNamn = 'akkafrakt' AND ViewOrdrar.Skeppningsdatum='2016-04-14'
SELECT * FROM ViewOrdrar WHERE ViewOrdrar.Skeppningsdatum = @Skeppdatum
GO

EXEC spVisaOrdrarDatum '2016-04-14'

--Visa antal order som ska skeppas för fraktbolagen.
IF OBJECT_ID (N'spVisaAntalOrderFrakbolagen', N'P') IS NOT NULL
    DROP PROC spVisaAntalOrderFrakbolagen;
GO
CREATE PROC spVisaAntalOrderFrakbolagen
AS
SELECT ViewOrdrar.FraktbolagsNamn , Count(*) as 'Antal Ordrar' FROM  ViewOrdrar GROUP BY ViewOrdrar.FraktbolagsNamn ORDER BY COUNT(*) DESC
GO

EXEC spVisaAntalOrderFrakbolagen

----•• Visa antal produkter som en tillverkare tillverkar. Ska sökas med namnet på  "Tillverkarbolaget"
IF OBJECT_ID (N'spVisaProdukterVissTillverkare', N'P') IS NOT NULL
    DROP PROC spVisaProdukterVissTillverkare;
GO
CREATE PROC spVisaProdukterVissTillverkare
(
@TillverkarNamn nvarchar(50) ='skanska'
)
AS

SELECT @TillverkarNamn AS 'Tillverkarbolag', COUNT(*) AS AntalProdukter
FROM     dbo.tblProdukter LEFT OUTER JOIN
                  dbo.tblTillverkarID ON dbo.tblProdukter.TillverkarID = dbo.tblTillverkarID.TillverkarID
WHERE  (dbo.tblTillverkarID.TillverkarNamn = @TillverkarNamn)
GO

EXEC spVisaProdukterVissTillverkare 'skanska'


----Om en produkt inte är tillgänglig så kan det inte ingå i en order. 
----VG uppgift, kan lösas med villkor och print. Kan också lösas av de som har läst på triggers med en AFTER INSERT trigger.
---2 lösningsprocedurer beroende om man vill skapa en helt ny order alternativt lägga till en delorder till en befintlig order

 
--Lägga till en ny delorder till en befintlig order.
--procedure som skickar sparar delordern utifrån befintligt ordernummer givet att produkten finns och är tillgänglig.
---om ordernumret inte finns eller produkten inte finns eller är tillgänglig skrivs medellande till print och inget bokas
--ALTERNATIVT
--en procedur där man bokar en ny order med ett nytt ordernr.
---produkten inte finns eller är tillgänglig skrivs medellande till print och inget bokas



IF OBJECT_ID (N'spBokaNyDelorder', N'P') IS NOT NULL
    DROP PROC spBokaNyDelorder;
GO

CREATE PROC spBokaNyDelorder
(
@OrderNummer int,
@Antalprodukter int,
@ProduktNamn nvarchar(50)
)
AS

IF (select dbo.OrderID(@OrderNummer)) is Null 
BEGIN
PRINT 'Finns ingen befintlig order med det ordernumret, inget är sparat'
RETURN
END
ELSE
BEGIN
IF (dbo.GetProductID(@ProduktNamn) is Null)
 BEGIN
 PRINT @ProduktNamn + ' går inte att beställa, välj annan produkt'
	RETURN
 END
 ELSE
BEGIN
IF (dbo.CheckRedanBokad(@ProduktNamn,@OrderNummer) is not Null)
BEGIN
 PRINT 'Delordern är redan bokad, du MÅSTE boka den på ett nytt ordernummer'
	RETURN
END
ELSE
BEGIN
INSERT INTO tblOrderProdukt(AntalProdukter,ProduktID,OrderID)
 VALUES (@Antalprodukter, dbo.GetProductID(@ProduktNamn), dbo.OrderID(@OrderNummer));
END
END
END
GO
EXEC spBokaNyDelorder 105, 20,'NikeSkor'
EXEC spBokaNyDelorder 106, 20,'BILTESLA'










 --INSERT INTO tblOrder(FraktbolagID,KundID,Skeppningsdatum,Orderdatum,Orderdatum,OrderNummer)
 --VALUES ('Cardinal','Tom B. Erichsen','Skagen 21','Stavanger','4006','Norway');










IF OBJECT_ID (N'GetNextOrderNr', N'FN') IS NOT NULL
    DROP FUNCTION GetNextOrderNr;
GO
CREATE FUNCTION GetNextOrderNr
(
) 
RETURNS INT 
AS 
BEGIN
    DECLARE @var INT 
    SELECT @var=1+(SELECT TOP 1 tblOrder.OrderNummer from tblOrder ORDER by tblOrder.OrderNummer desc) 
    RETURN @var 
END

IF OBJECT_ID (N'OrderID', N'FN') IS NOT NULL
    DROP FUNCTION OrderID;
GO
CREATE FUNCTION OrderID
(
@OrderNr int
) 
RETURNS INT 
AS 
BEGIN
    DECLARE @var INT 
    SELECT @var=(SELECT tblOrder.OrderID from tblOrder where tblOrder.OrderNummer = @OrderNr) 
    RETURN @var 
END

select  dbo.OrderID(101); 

select  dbo.GetNextOrderNr(); 

IF OBJECT_ID (N'CheckRedanBokad', N'FN') IS NOT NULL
    DROP FUNCTION CheckRedanBokad;
GO
CREATE FUNCTION CheckRedanBokad
(
@ProduktNamn AS nvarchar(50), 
@OrderNummer as int
) 

RETURNS  INT
AS 
BEGIN
RETURN (SELECT DISTINCT dbo.tblOrder.OrderID FROM 
dbo.tblOrder INNER JOIN dbo.tblOrderProdukt ON dbo.tblOrder.OrderID = dbo.tblOrderProdukt.OrderID INNER JOIN dbo.tblProdukter ON dbo.tblOrderProdukt.ProduktID = dbo.tblProdukter.ProduktID
WHERE  (dbo.tblOrder.OrderNummer = @OrderNummer) AND (dbo.tblProdukter.ProduktNamn = @ProduktNamn))
END
GO

select  dbo.CheckRedanBokad('NikeSkor',104) ;



IF OBJECT_ID (N'GetProductID', N'FN') IS NOT NULL
    DROP FUNCTION GetProductID;
GO
CREATE FUNCTION GetProductID(@ProduktNamn1 AS nvarchar(50)='NikeSkor') 

returns int
AS 

BEGIN
    RETURN (SELECT distinct tblProdukter.ProduktID from tblProdukter where tblProdukter.ProduktNamn = @ProduktNamn1 and tblProdukter.Tillgänglig=1 )
     
END
GO
select  dbo.GetProductID('NikeSkor') ;

Declare @ProduktNamn nvarchar(50)='NikeSkor'
SELECT tblProdukter.ProduktID from tblProdukter where tblProdukter.ProduktNamn = @ProduktNamn
