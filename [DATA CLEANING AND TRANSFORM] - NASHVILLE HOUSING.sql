-- Xem dữ liệu --
Select top 5 *
from dbo.Nashville_Housing

--------------------------------------------------------------------------------------------------------
-- Chuyển lại định dạng cột SaleDate về dạng Date --

Select SaleDate, Convert(Date,SaleDate) as SaleDateConverted
from dbo.Nashville_Housing

--------------------------------------------------------------------------------------------------------
-- Xử lý cột PropertyAddress --
-- Kiểm tra xem liệu có phải mỗi ParcelID đại diện cho một PropertyAddress hay không
-- Nếu đúng thì fill các giá trị NULL bằng PropertyAddress

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
From dbo.Nashville_Housing a
Join dbo.Nashville_Housing b
    On a.ParcelID = b.ParcelID
    And a.UniqueID <> b.UniqueID
Where a.PropertyAddress is Null
-- (Chạy lại đoạn code trên để kiểm tra, sau khi Fill đã không còn giá trị Null nào nữa)
--> Mỗi ParcelID đại diện cho một PropertyAddress
-- Tiến hành Fill Null Value

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress) 
From dbo.Nashville_Housing a
Join dbo.Nashville_Housing b
    On a.ParcelID = b.ParcelID
    And a.UniqueID <> b.UniqueID
Where a.PropertyAddress is Null

--------------------------------------------------------------------------------------------------------
-- Tách Địa chỉ BĐS thành các cột City, Address, State --

Select PropertyAddress
From dbo.Nashville_Housing

/* Hàm CHARINDEX được sử dụng để tìm vị trí xuất hiện đầu tiên của một chuỗi 
con trong một chuỗi lớn.

Cú pháp: CHARINDEX(search_string, string_expression [, start_location])

Hàm CHARINDEX trả về một số nguyên là vị trí đầu tiên của chuỗi con được tìm thấy trong chuỗi lớn. 
Nếu chuỗi con không được tìm thấy, hàm sẽ trả về 0.

Cú pháp CHARINDEX(search_string, string_expression [, start_location]) */

-- Tạo cột Address --
Select SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress) -1) as Address 
From dbo.Nashville_Housing
-- Note: Thêm -1 để lấy lấy ra ký tự đầu tiên theo dấu ',' và lùi đi 1 index --
-- Tạo cột City
Select SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) as Address 
From dbo.Nashville_Housing

-- Tiến hành Update vào bảng --

-- Thêm cột PropertySplitAddress --
Alter Table dbo.Nashville_Housing
Add PropertySplitAddress Nvarchar(50)
-- Fill giá trị vào cột PropertySplitAddress --
Update dbo.Nashville_Housing
Set PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',',PropertyAddress) -1)


-- Thêm cột PropertySplitCity --
Alter Table dbo.Nashville_Housing
Add PropertySplitCity Nvarchar(50)
-- Fill giá trị vào cột PropertySplitCity --
Update dbo.Nashville_Housing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))

--------------------------------------------------------------------------------------------------------
-- Xử lý cột OwnerAddress --

/* Hàm PARSENAME được sử dụng để phân tích một chuỗi thành các phần tách biệt dựa trên dấu chấm (.)

Cú pháp: PARSENAME('object_name', part) */

-- Thay thế dấu ',' thành dấu '.' rồi sử dụng hàm PARSENAME --

Select 
    PARSENAME(Replace(OwnerAddress, ',', '.'), 3),
    PARSENAME(Replace(OwnerAddress, ',', '.'), 2),
    PARSENAME(Replace(OwnerAddress, ',', '.'), 1)
From dbo.Nashville_Housing

-- Update vào bảng --

-- Thêm cột OwnerSplitAddress --
Alter Table dbo.Nashville_Housing
Add OwnerSplitAddress Nvarchar(50)
-- Fill giá trị vào cột OwnerSplitAddress --
Update dbo.Nashville_Housing
Set OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3)


-- Thêm cột OwnerSplitCity --
Alter Table dbo.Nashville_Housing
Add OwnerSplitCity Nvarchar(50)
-- Fill giá trị vào cột PropertySplitCity --
Update dbo.Nashville_Housing
Set OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2)

-- Thêm cột OwnerSplitState --
Alter Table dbo.Nashville_Housing
Add OwnerSplitState Nvarchar(50)
-- Fill giá trị vào cột PropertySplitCity --
Update dbo.Nashville_Housing
Set OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)

--------------------------------------------------------------------------------------------------------
-- Xử lý cột SoldAsVacant
-- Check Distinct Value

Select distinct(SoldAsVacant)
from dbo.Nashville_Housing

-- Tiến hành thay thế 'Y' thành 'Yes' và 'N' thành 'No'

Select SoldAsVacant
    ,Case When SoldAsVacant = 'Y' Then 'Yes'
          When SoldAsVacant = 'N' Then 'No'
          Else SoldAsVacant
          End
from dbo.Nashville_Housing

-- Tiến hành Update bảng gốc --
Update dbo.Nashville_Housing
Set SoldAsVacant = Case When SoldAsVacant = 'Y' Then 'Yes'
                        When SoldAsVacant = 'N' Then 'No'
                        Else SoldAsVacant
                        End
--------------------------------------------------------------------------------------------------------
-- Xử lý các giá trị bị Duplicated --

With Cte as(
Select *
    ,ROW_NUMBER() OVER(PARTITION BY ParcelID, 
    PropertyAddress, SalePrice, SaleDate, LegalReference 
    ORDER BY UniqueID) as Row_num
From dbo.Nashville_Housing
)
-- Note: Nếu Row_num > 1 => Duplicates
Delete
From Cte
Where Row_num > 1

--------------------------------------------------------------------------------------------------------
-- Xoá bớt các cột không cần thiết --

Alter Table dbo.Nashville_Housing
Drop Column OwnerAddress, PropertyAddress, TaxDistrict, SaleDate

Select top 5 *
from dbo.Nashville_Housing