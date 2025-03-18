SELECT * FROM Housing_Data.nashville_housing;

-- Cleaning Data using SQL queries
-- ------------------------------------------------------------------------
-- converting blank records to NULL among multiple attributes
update Housing_Data.nashville_housing
set PropertyAddress = NULLIF(PropertyAddress, ''),
	OwnerName = NULLIF(OwnerName, ''),
    OwnerAddress = NULLIF(OwnerAddress, ''),
    Acreage = NULLIF(Acreage, ''),
    taxdistrict = NULLIF(taxdistrict, ''),
    landvalue = NULLIF(landvalue, ''),
    buildingvalue = NULLIF(buildingvalue, ''),
    totalvalue = NULLIF(totalvalue, ''),
    yearbuilt = NULLIF(yearbuilt, ''),
    bedrooms = NULLIF(bedrooms, ''),
    fullbath = NULLIF(fullbath, ''),
    halfbath = NULLIF(halfbath, '')
;
-- ------------------------------------------------------------------------- 
-- Standardize Date Format

-- Testing
SELECT saledate, STR_TO_DATE(SaleDate, '%M %d, %Y') AS SaleDateConverted
FROM Housing_Data.nashville_housing;

-- add a new column for 'ConvertedSaleDate' here to keep the original one 
-- Updating
Alter table Housing_Data.nashville_housing
add SaleDateConverted DATE;

UPDATE Housing_Data.nashville_housing
SET SaleDateConverted = STR_TO_DATE(SaleDate, '%M %d, %Y');
SELECT SaleDate, SaleDateConverted FROM Housing_Data.nashville_housing;

-- ---------------------------------------------------------------------------
-- Populate Property Address Data

SELECT PropertyAddress 
FROM Housing_Data.nashville_housing
where PropertyAddress is Null -- Populated Null values in the below query
;

-- Finding Duplicate records
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM Housing_Data.nashville_housing a
JOIN Housing_Data.nashville_housing b
on a.ParcelID=b.ParcelID
AND a.UniqueID <> b.UniqueID
;

-- Duplicates records which has NULL values
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM Housing_Data.nashville_housing a
JOIN Housing_Data.nashville_housing b
on a.ParcelID=b.ParcelID
AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress IS NULL
;

-- Writing PropertyAddress where it is null -- Testing if this query works or not
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress, b.PropertyAddress) AS UpdatedPropertyAddress -- ISNULL Command
FROM Housing_Data.nashville_housing a
JOIN Housing_Data.nashville_housing b
on a.ParcelID=b.ParcelID
AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress IS NULL
;

-- Updating
UPDATE Housing_Data.nashville_housing a
JOIN Housing_Data.nashville_housing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- ----------------------------------------------------------------------------
-- Breaking out Property Address into individual columns(Address, City, State)

SELECT PropertyAddress 
FROM Housing_Data.nashville_housing;

-- Using Substring and Character Index / CharIndex(',', PropertyAddress) -- Not fot MySQL
-- INSTR( PropertyAddress, ',') for MySQL workbench
Use Housing_Data;
select
substring(PropertyAddress, 1, INSTR( PropertyAddress, ',') -1) as Address
, substring(PropertyAddress, INSTR( PropertyAddress, ',') +2 , LENGTH(PropertyAddress)) as City
FROM Housing_Data.nashville_housing;

-- Adding new columns to split the address

Alter table Housing_Data.nashville_housing
Add PropertySplitAddress VARCHAR(255);

Update Housing_Data.nashville_housing
Set PropertySplitAddress = substring(PropertyAddress, 1, INSTR( PropertyAddress, ',') -1);


Alter table Housing_Data.nashville_housing
Add PropertySplitCity VARCHAR(255);

Update Housing_Data.nashville_housing
Set PropertySplitCity = substring(PropertyAddress, INSTR( PropertyAddress, ',') +2 , LENGTH(PropertyAddress));

-- --------------------------------------------------------------------------------------
-- doing the same for owner address
-- Breaking out Owner Address into individual columns(Address, City, State)

SELECT OwnerAddress 
FROM Housing_Data.nashville_housing;

Use Housing_Data;
select
substring(OwnerAddress , 1, INSTR( OwnerAddress, ',') -1) as Address
, substring(OwnerAddress, INSTR( OwnerAddress, ',') + 2, INSTR(SUBSTRING(OwnerAddress, INSTR(OwnerAddress, ',') + 2), ',') - 1) AS City
, substring(OwnerAddress, INSTR( OwnerAddress, ',') + INSTR(SUBSTRING(OwnerAddress, INSTR(OwnerAddress, ',') + 2), ',') + 2) AS State
FROM Housing_Data.nashville_housing;

-- Another way to do this
-- for microsoft server
/*
SELECT 
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM Housing_Data.nashville_housing;
*/
-- for MySQL workbench
/*
SELECT
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Address,
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS City,
    SUBSTRING_INDEX(OwnerAddress, ',', -1) AS State
FROM Housing_Data.nashville_housing;
*/

-- Adding new columns to split the address

Alter table Housing_Data.nashville_housing
Add OwnerSplitAddress VARCHAR(255);

Update Housing_Data.nashville_housing
Set OwnerSplitAddress = substring(OwnerAddress , 1, INSTR( OwnerAddress, ',') -1);


Alter table Housing_Data.nashville_housing
Add OwnerSplitCity VARCHAR(255);

Update Housing_Data.nashville_housing
Set OwnerSplitCity = substring(OwnerAddress, INSTR( OwnerAddress, ',') + 2, INSTR(SUBSTRING(OwnerAddress, INSTR(OwnerAddress, ',') + 2), ',') - 1);

Alter table Housing_Data.nashville_housing
Add OwnerSplitState VARCHAR(255);

Update Housing_Data.nashville_housing
Set OwnerSplitState = substring(OwnerAddress, INSTR( OwnerAddress, ',') + INSTR(SUBSTRING(OwnerAddress, INSTR(OwnerAddress, ',') + 2), ',') + 2);

-- --------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in 'Sold as Vacant' field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From Housing_Data.nashville_housing
Group by SoldAsVacant
order by 2;

Select SoldAsVacant,
 CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END AS SoldAsVacant_Updated
From Housing_Data.nashville_housing;

Update Housing_Data.nashville_housing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
;

-- ----------------------------------------------------------------------------
-- Remove Duplicates
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
From Housing_Data.nashville_housing
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress;

Select *
From Housing_Data.nashville_housing;

-- ----------------------------------------------------------------------------
-- Delete Unused Columns

Select *
From Housing_Data.nashville_housing;

ALTER TABLE Housing_Data.nashville_housing
DROP COLUMN OwnerAddress, 
DROP COLUMN  TaxDistrict,
DROP COLUMN PropertyAddress, 
DROP COLUMN SaleDate;
