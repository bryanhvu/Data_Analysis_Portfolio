/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM NashvilleHousingData.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM NashvilleHousingData.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM NashvilleHousingData.dbo.NashvilleHousing



 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

SELECT *
FROM NashvilleHousingData.dbo.NashvilleHousing
ORDER BY ParcelID

-- Properties with Identical ParcelIDs Should Have the Same Property Address

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousingData.dbo.NashvilleHousing AS a
JOIN NashvilleHousingData.dbo.NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousingData.dbo.NashvilleHousing AS a
JOIN NashvilleHousingData.dbo.NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL



--------------------------------------------------------------------------------------------------------------------------

-- Split Property and Owner Addresses into Individual Columns (Address, City, State)


SELECT PropertyAddress
FROM NashvilleHousingData.dbo.NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM NashvilleHousingData.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD 
	PropertyStreetAddress NVARCHAR(255),
	PropertyCity NVARCHAR(255);

UPDATE NashvilleHousing
SET 
	PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
	PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));


SELECT PropertyStreetAddress, PropertyCity
FROM NashvilleHousingData.dbo.NashvilleHousing


-- PARSENAME only looks at '.', so we replace commas in the owneraddress to facillitate quick parsing

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousingData.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD 
	OwnerStreetAddress NVARCHAR(255),
	OwnerCity NVARCHAR(255),
	OwnerState NVARCHAR(255);
	
UPDATE NashvilleHousing
SET
	OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

SELECT *
FROM NashvilleHousingData.dbo.NashvilleHousing



--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field


SELECT DISTINCT(SoldAsVacant), COUNT(SoldASVacant)
FROM NashvilleHousingData.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC


SELECT SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM NashvilleHousingData.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant =
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates


SELECT DISTINCT([UniqueID ]), COUNT([UniqueID ]) as Instances
FROM NashvilleHousingData.dbo.NashvilleHousing
GROUP BY [UniqueID ]
HAVING COUNT([UniqueID ]) > 1

-- From the above query, there are no records with duplicate UniqueId's
-- Lets check using other columns

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY 
		ParcelID,
		SalePrice,
		SaleDate,
		LegalReference
		ORDER BY UniqueID
	) as Row_Num
FROM NashvilleHousingData.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE Row_Num > 1



---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


SELECT *
FROM NashvilleHousingData.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
