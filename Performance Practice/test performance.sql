SELECT COUNT(*) FROM MmCt
SELECT COUNT(*) FROM glct

EXEC sp_spaceused 'dbo.glct';

SELECT *
INTO glctTesttt
FROM dbo.glct


SELECT * FROM glctTesttt

SELECT id FROM glctTesttt



SELECT ma_kh, ma_bp
FROM glctTesttt
WHERE ma_cty = '001' AND id = '7ED57C0B-627E-41B3-8004-E5B79DB80CC5' AND ma_ct = 'PO6'

SELECT ma_kh, ma_bp
FROM glctTesttt
WHERE ma_cty = '001' AND id = '7ED57C0B-627E-41B3-8004-E5B79DB80CC5' AND ma_ct = 'PO6'
OPTION (MERGE JOIN)

SELECT ma_kh, ma_bp
FROM glctTesttt WITH (INDEX(idx_id_glctTesttt))
WHERE ma_cty = '001' AND id = '7ED57C0B-627E-41B3-8004-E5B79DB80CC5'

SELECT ma_kh, ma_bp
FROM glctTesttt
WHERE id = '7ED57C0B-627E-41B3-8004-E5B79DB80CC5' AND ma_cty = '001'


CREATE NONCLUSTERED INDEX idx_id_glctTesttt
ON dbo.glctTesttt(id)
INCLUDE(ma_kh, ma_bp)

CREATE NONCLUSTERED INDEX idx_id_glctTesttt1
ON dbo.glctTesttt(id,ma_cty)
INCLUDE(ma_kh, ma_bp)

DROP INDEX idx_id_glctTesttt1
ON dbo.glctTesttt;





CREATE CLUSTERED COLUMNSTORE INDEX idx_glctTesttt_CS
ON dbo.glctTesttt

SELECT * FROM dbo.glctTesttt

SELECT COUNT(*) FROM glctTesttt WHERE nam = 2021

SELECT COUNT(*) FROM glctTesttt WHERE ma_ct = 'PO1'

SELECT COUNT(*) FROM glctTesttt WHERE ma_ct = CAST('CA2' AS varchar(20));
GO





-- inner join: join các dòng của 2 bên (khi 2 bên != null)
-- left outer join: join toàn bộ các dòng của bảng bên trái (kể cả khi bên phải null)
-- left semi join: join toàn bộ các dòng của bảng bên trái mà bên phải không null
-- left anti semi join: join toàn bộ các dòng của bảng bên trái mà bên phải là null




-- Dự án DaiTamLong
;
WITH CTE_Insert AS (
	SELECT *, 1 AS [count]
	FROM MmCt

	UNION ALL

	SELECT ct.*, 
		cte.[count] + 1 AS [count]
	FROM MmCt ct
	JOIN CTE_Insert cte ON cte.ma_cty = ct.ma_cty AND cte.id_ph = ct.id_ph AND cte.stt = ct.stt
	WHERE cte.[count] < 2
)
SELECT * 
INTO MmCtTESTTTTTTTT
FROM CTE_Insert
;
CREATE NONCLUSTERED INDEX idx_ma_cty_id_ph
ON MmCtTESTTTTTTTT(ma_cty, id_ph)
CREATE CLUSTERED INDEX idx_MaCty_NgayCt
ON MmCtTESTTTTTTTT(ma_cty, ngay_ct)

DROP INDEX idx_ma_cty_id_ph ON MmCtTESTTTTTTTT
DROP INDEX idx_MaCty_NgayCt ON MmCtTESTTTTTTTT

SELECT * FROM MmCtTESTTTTTTTT

DROP TABLE MmCtTESTTTTTTTT

UPDATE STATISTICS MmCtTESTTTTTTTT;

SELECT *
FROM MmCtTESTTTTTTTT
WHERE ma_ct = 'MMB' 
	OR (
		ma_ct = 'MMA' 
		AND 
		id_ph NOT IN (SELECT id_mma FROM MmCtTESTTTTTTTT WHERE ma_cty = N'001')
	)

SELECT *
FROM MmCt
WHERE ma_ct = 'MMB' 
UNION ALL
SELECT *
FROM MmCt
WHERE ma_ct = 'MMA' AND id_ph NOT IN (SELECT id_mma FROM MmCt WHERE ma_cty = N'001')
OPTION (HASH JOIN)

SELECT 
	CASE 
		WHEN ct.ngay_lct = '' THEN ''
		ELSE ISNULL(FORMAT(ct.ngay_lct, 'dd/MM/yyyy'), '')
	END AS str_date
FROM MmCt ct
WHERE ma_ct = 'MMB' 
	OR (
		ma_ct = 'MMA' 
		AND 
		id_ph NOT IN (
			SELECT id_mma 
			FROM MmCt 
			WHERE ma_cty = N'001'
		)
	)

SELECT 
	CASE 
		WHEN ct.ngay_lct = '' THEN ''
		ELSE ISNULL(CONVERT(varchar(10), ct.ngay_lct, 103), '')
	END AS str_date
FROM MmCt ct
WHERE ma_ct = 'MMB' 
	OR (
		ma_ct = 'MMA' 
		AND 
		id_ph NOT IN (
			SELECT id_mma 
			FROM MmCt 
			WHERE ma_cty = N'001'
		)
	)


SELECT 
	CASE 
		WHEN ct.ngay_lct = '' THEN ''
		ELSE ISNULL(CONVERT(varchar(10), ct.ngay_lct, 103), '')
	END AS str_date
FROM MmCtTESTTTTTTTT ct
WHERE ma_ct = 'MMB' 
	OR (
		ma_ct = 'MMA' 
		AND 
		id_ph NOT IN (
			SELECT id_mma 
			FROM MmCtTESTTTTTTTT 
			WHERE ma_cty = N'001'
		)
	)

SELECT 
	CASE 
		WHEN ct.ngay_lct = '' THEN ''
		ELSE ISNULL(FORMAT(ct.ngay_lct, 'dd/MM/yyyy'), '')
	END AS str_date
FROM MmCtTESTTTTTTTT ct
WHERE ma_ct = 'MMB' 
	OR (
		ma_ct = 'MMA' 
		AND 
		id_ph NOT IN (
			SELECT id_mma 
			FROM MmCtTESTTTTTTTT 
			WHERE ma_cty = N'001'
		)
	)




-- Compare 2 procedures

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
exec asMMRpt_BaoCaoSanXuatChiTiet1
@pMa_cty=N'001',@pNam=2025,@pLang=N'vi-VN',@pUser=N'sysadmin',
@pNgay_ct1=N'2025-10-01T00:00:00',
@pNgay_ct2=N'2025-10-31T00:00:00',
@pMa_kh=N'',@pMa_vt=N''
go
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

print '---------------------NEXT------------------------'

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
exec asMMRpt_BaoCaoSanXuatChiTiet2
@pMa_cty=N'001',@pNam=2025,@pLang=N'vi-VN',@pUser=N'sysadmin',
@pNgay_ct1=N'2025-10-01T00:00:00',
@pNgay_ct2=N'2025-10-31T00:00:00',
@pMa_kh=N'',@pMa_vt=N''
go
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;



exec asMMRpt_BaoCaoSanXuatChiTiet2
@pMa_cty=N'001',@pNam=2025,@pLang=N'vi-VN',@pUser=N'sysadmin',
@pNgay_ct1=N'2025-10-01T00:00:00',
@pNgay_ct2=N'2025-10-31T00:00:00',
@pMa_kh=N'',@pMa_vt=N''
go
exec asMMRpt_BaoCaoSanXuatChiTiet1
@pMa_cty=N'001',@pNam=2025,@pLang=N'vi-VN',@pUser=N'sysadmin',
@pNgay_ct1=N'2025-10-01T00:00:00',
@pNgay_ct2=N'2025-10-31T00:00:00',
@pMa_kh=N'',@pMa_vt=N''
go



SELECT 
    DB_NAME(database_id) AS [Database],
    OBJECT_NAME(object_id, database_id) AS [ProcedureName],
    execution_count,
    total_elapsed_time / 1000.0 AS total_ms,
    total_worker_time / 1000.0 AS cpu_ms,
    total_logical_reads,
    total_physical_reads,
    (total_elapsed_time / execution_count) / 1000.0 AS avg_elapsed_ms,
    (total_worker_time / execution_count) / 1000.0 AS avg_cpu_ms
FROM sys.dm_exec_procedure_stats
WHERE DB_NAME(database_id) = 'SalesDB'
  AND OBJECT_NAME(object_id, database_id) IN ('asMMRpt_BaoCaoSanXuatChiTiet1', 'asMMRpt_BaoCaoSanXuatChiTiet2')
ORDER BY avg_elapsed_ms;
GO



-- 04/10/2025 -- KhoaLD -- Task 21660:QUẢN LÝ SẢN XUẤT | BÁO CÁO | Theo dõi sản xuất gia công (menuid:15.20.02) - thêm mới báo cáo
IF OBJECT_ID('dbo.asMMRpt_BaoCaoSanXuatChiTiet1') IS NOT NULL
	DROP PROCEDURE dbo.asMMRpt_BaoCaoSanXuatChiTiet1
GO
CREATE PROCEDURE [dbo].[asMMRpt_BaoCaoSanXuatChiTiet1]
	@pMa_cty nvarchar(5) = '001',
	@pNam int = 2025,
	@pLang nvarchar(20) = 'vi-VN',
	@pUser nvarchar(20) = '',

	@pNgay_ct1	smalldatetime = '' ,
	@pNgay_ct2	smalldatetime = '',
	@pMa_kh nvarchar(20) = '',
	@pMa_vt nvarchar(20) = ''
AS
	SET NOCOUNT ON

	IF @pNgay_ct1 = ''
		SET @pNgay_ct1 = GETDATE()
	IF @pNgay_ct2 = ''
		SET @pNgay_ct2 = GETDATE()

	DECLARE @sql nvarchar(MAX),
		@sqlWhere nvarchar(MAX),
		@ParamDefines nvarchar(500)

	IF OBJECT_ID('tempdb..#temp') IS NOT NULL 
		DROP TABLE #temp
	CREATE TABLE #temp
	(
		ma_cty			NVARCHAR(5) DEFAULT '',
		id_ph			NVARCHAR(50) DEFAULT '',
		ma_ct			NVARCHAR(3) DEFAULT '',
		ngay_lct		SMALLDATETIME DEFAULT '',
		str_ngay_lct	NVARCHAR(15) DEFAULT '',
		cuser			NVARCHAR(1000) DEFAULT '',
		so_ct			NVARCHAR(12) DEFAULT '',
		ma_kh			NVARCHAR(20) DEFAULT '',
		ten_kh_ngan		NVARCHAR(15) DEFAULT '',
		ma_dcs			NVARCHAR(20) DEFAULT '',
		ma_htxl			NVARCHAR(20) DEFAULT '',
		ten_vt			NVARCHAR(200) DEFAULT '',
		ma_bs			NVARCHAR(20) DEFAULT '',
		kh_son			NVARCHAR(20) DEFAULT '',
		mau_son			NVARCHAR(50) DEFAULT '',
		nha_pp			NVARCHAR(150) DEFAULT '',
		nguon_son		NVARCHAR(10) DEFAULT '',
		sl_son			DECIMAL(19,4) DEFAULT 0,
		ma_hts			NVARCHAR(20) DEFAULT '',
		do_day			NVARCHAR(10) DEFAULT '',
		ngay_giao_hang	SMALLDATETIME DEFAULT '',
		so_ct_lk		NVARCHAR(1000) DEFAULT '',
		lan_xl_loi		INT DEFAULT 0,
		ngay_ct			SMALLDATETIME DEFAULT '',
		dvt				NVARCHAR(20) DEFAULT '',
		dvt_mua			NVARCHAR(20) DEFAULT '',
		sl_dvt_mua		DECIMAL(19,4) DEFAULT 0,
		so_luong		DECIMAL(19,4) DEFAULT 0,
		sl_dat			DECIMAL(19,4) DEFAULT 0,
		sl_dd			DECIMAL(19,4) DEFAULT 0,
		sl_loi			DECIMAL(19,4) DEFAULT 0,
		sl_hong			DECIMAL(19,4) DEFAULT 0,
		ghi_chu			NVARCHAR(255) DEFAULT '',
		loai_hang		NVARCHAR(1) DEFAULT '',
		sl_loi_mma		DECIMAL(19,4) DEFAULT 0,
		dt_kh			DECIMAL(19,4) DEFAULT 0,
		dt_th			DECIMAL(19,4) DEFAULT 0,
		ma_vt			NVARCHAR(20) DEFAULT '',
		ten_dcs			NVARCHAR(255) DEFAULT '',
		ten_htxl		NVARCHAR(255) DEFAULT '',
		ten_hts			NVARCHAR(255) DEFAULT '',
		tl_ht			DECIMAL(19,4) DEFAULT 0,
		cap int DEFAULT 0,
		bold int DEFAULT 0
	)
	CREATE NONCLUSTERED INDEX idx_temp_cap
	ON #temp (cap, bold)

	-- Xây dựng dữ liệu tạm, lọc mmct theo đk vào bảng #temp
	INSERT INTO #temp (
		ma_cty,
		id_ph,
		ma_ct,
		ngay_lct, 
		str_ngay_lct,
		cuser, 
		so_ct,
		ma_kh, 
		ten_kh_ngan, 
		ma_dcs, 
		ma_htxl, 
		ten_vt,
		ma_bs,
		kh_son,
		mau_son, 
		nha_pp, 
		nguon_son, 
		sl_son,
		ma_hts, 
		do_day,
		ngay_giao_hang,
		so_ct_lk, 
		lan_xl_loi,
		ngay_ct, 
		dvt,
		dvt_mua, 
		sl_dvt_mua, 
		so_luong, 
		sl_dat,
		sl_dd, 
		sl_loi, 
		sl_hong,
		ghi_chu,
		loai_hang,
		sl_loi_mma,
		ma_vt,
		cap, 
		bold)
	SELECT 
		ct.ma_cty,
		ct.id_ph,
		ct.ma_ct,
		ct.ngay_lct, 
		CASE 
			WHEN ct.ngay_lct = '' THEN ''
			ELSE ISNULL(FORMAT(ct.ngay_lct, 'dd/MM/yyyy'), '')
		END, 
		ct.cuser, 
		ct.so_ct,
		ct.ma_kh, 
		ct.ten_kh_ngan, 
		ct.ma_dcs, 
		ct.ma_htxl, 
		ct.ten_vt,
		ct.ma_bs,
		ct.kh_son,
		ct.mau_son, 
		ct.nha_pp, 
		ct.nguon_son, 
		ct.sl_son,
		ct.ma_hts, 
		ct.do_day,
		ct.ngay_giao,
		ct.so_ct_lk, 
		ct.lan_xl_loi,
		ct.ngay_ct, 
		ct.dvt,
		ct.dvt_mua, 
		ct.sl_dvt_mua, 
		ct.so_luong, 
		ct.sl_dat,
		ct.sl_dd, 
		ct.sl_loi, 
		ct.sl_hong,
		ct.ghi_chu,
		ct.loai_hang,
		ct.sl_loi_mma,
		ct.ma_vt,
		1, 
		0
	FROM MmCt ct
	WHERE ct.ma_cty = @pMa_cty 
		AND ct.ngay_ct BETWEEN @pNgay_ct1 AND @pNgay_ct2
		AND (@pMa_kh = '' OR ct.ma_kh = @pMa_kh)
		AND (@pMa_vt = '' OR ct.ma_vt = @pMa_vt)
		AND (ma_ct = 'MMB' OR (ma_ct = 'MMA' AND id_ph NOT IN (SELECT id_mma FROM MmCt WHERE ma_cty = @pMa_cty)))

	-- Thêm dòng tổng theo ngay_ct
	INSERT INTO #temp (
		str_ngay_lct,
		sl_dvt_mua, 
		so_luong, 
		sl_dat, 
		sl_dd,
		sl_loi,
		sl_hong,
		dt_kh,
		dt_th,
		ngay_ct,
		cap,
		bold)
	SELECT 
		N'Cộng:',
		ISNULL(SUM(sl_dvt_mua), 0),
		ISNULL(SUM(so_luong), 0),
		ISNULL(SUM(sl_dat), 0),
		ISNULL(SUM(sl_dd), 0),
		ISNULL(SUM(sl_loi), 0),
		ISNULL(SUM(sl_hong), 0),
		ISNULL(SUM(dt_kh), 0),
		ISNULL(SUM(dt_th), 0),
		ngay_ct,
		1,
		1
	FROM #temp
	WHERE cap = 1 AND bold = 0
	GROUP BY ngay_ct
	
	-- Thêm dòng tổng tất cả các dòng bôi đỏ
	INSERT INTO #temp (
		str_ngay_lct,
		sl_dvt_mua, 
		so_luong, 
		sl_dat, 
		sl_dd,
		sl_loi,
		sl_hong,
		dt_kh,
		dt_th,
		cap,
		bold)
	SELECT
		N'Tổng cộng:',
		ISNULL(SUM(sl_dvt_mua), 0),
		ISNULL(SUM(so_luong), 0),
		ISNULL(SUM(sl_dat), 0),
		ISNULL(SUM(sl_dd), 0),
		ISNULL(SUM(sl_loi), 0),
		ISNULL(SUM(sl_hong), 0),
		ISNULL(SUM(dt_kh), 0),
		ISNULL(SUM(dt_th), 0),
		2,
		1
	FROM #temp
	WHERE cap = 1 AND bold = 1

	-- Lấy thông tin báo cáo tổng hợp
	SELECT 
		ISNULL(SUM(sl_son), 0) AS sl_son,
		ISNULL(SUM(CASE WHEN loai_hang = '1' THEN so_luong ELSE 0 END), 0) AS sl_moi,
		ISNULL(SUM(CASE WHEN loai_hang = '3' THEN so_luong ELSE 0 END), 0) AS sl_loi,
		ISNULL(SUM(sl_dat), 0) AS sl_dat,
		ISNULL((SELECT SUM(ps_co) FROM GlCt WHERE tk LIKE '131%' AND ma_ct = 'sod' AND ngay_ct BETWEEN @pNgay_ct1 AND @pNgay_ct2), 0) AS doanh_thu,
		ISNULL(SUM(sl_loi), 0) - ISNULL(SUM(sl_loi_mma), 0) AS sl_loi_con,
		ISNULL(SUM(sl_hong), 0) AS sl_hong
	FROM #temp
	WHERE cap = 1 AND bold = 0

	-- Lấy thông tin chi tiết thực hiện
	SELECT 
		ct.ma_cty,
		ct.id_ph,
		ct.ma_ct,
		ct.ngay_lct AS sdt_ngay_lct,
		ct.str_ngay_lct AS ngay_lct,
		ct.cuser,
		ct.so_ct,
		ct.ten_kh_ngan,
		ct.ma_kh,
		ct.ten_dcs,
		ct.ten_htxl,
		ct.ten_vt,
		ct.ma_bs,
		ct.kh_son,
		ct.mau_son,
		ct.nha_pp,
		ct.nguon_son AS ma_nguon_son,
		CASE ct.nguon_son WHEN 'KH' THEN N'Khách hàng' WHEN 'CTY' THEN N'Công ty' ELSE '' END AS nguon_son,
		ct.sl_son,
		ct.ten_hts,
		ct.do_day,
		ct.ngay_giao_hang,
		ct.so_ct_lk,
		ct.lan_xl_loi,
		ct.ngay_ct,
		ct.dvt,
		ct.dvt_mua,
		ct.sl_dvt_mua,
		ct.so_luong,
		ct.sl_dat,
		ct.sl_dd,
		ct.sl_loi,
		ct.sl_hong,
		ct.tl_ht,
		ct.dt_kh,
		ct.dt_th,
		ct.ghi_chu,
		ct.cap,
		ct.bold
	FROM #temp ct
	ORDER BY cap ASC, ngay_ct ASC, bold ASC

	DROP TABLE #temp
	SET NOCOUNT OFF
GO


IF OBJECT_ID('dbo.asMMRpt_BaoCaoSanXuatChiTiet2') IS NOT NULL
	DROP PROCEDURE dbo.asMMRpt_BaoCaoSanXuatChiTiet2
GO
CREATE PROCEDURE [dbo].[asMMRpt_BaoCaoSanXuatChiTiet2]
	@pMa_cty nvarchar(5) = '001',
	@pNam int = 2025,
	@pLang nvarchar(20) = 'vi-VN',
	@pUser nvarchar(20) = '',

	@pNgay_ct1	smalldatetime = '' ,
	@pNgay_ct2	smalldatetime = '',
	@pMa_kh nvarchar(20) = '',
	@pMa_vt nvarchar(20) = ''
AS
	SET NOCOUNT ON

	IF @pNgay_ct1 = ''
		SET @pNgay_ct1 = GETDATE()
	IF @pNgay_ct2 = ''
		SET @pNgay_ct2 = GETDATE()

	DECLARE @sql nvarchar(MAX),
		@sqlWhere nvarchar(MAX),
		@ParamDefines nvarchar(500)

	IF OBJECT_ID('tempdb..#temp') IS NOT NULL 
		DROP TABLE #temp
	CREATE TABLE #temp
	(
		ma_cty			NVARCHAR(5) DEFAULT '',
		id_ph			NVARCHAR(50) DEFAULT '',
		ma_ct			NVARCHAR(3) DEFAULT '',
		ngay_lct		SMALLDATETIME DEFAULT '',
		str_ngay_lct	NVARCHAR(15) DEFAULT '',
		cuser			NVARCHAR(1000) DEFAULT '',
		so_ct			NVARCHAR(12) DEFAULT '',
		ma_kh			NVARCHAR(20) DEFAULT '',
		ten_kh_ngan		NVARCHAR(15) DEFAULT '',
		ma_dcs			NVARCHAR(20) DEFAULT '',
		ma_htxl			NVARCHAR(20) DEFAULT '',
		ten_vt			NVARCHAR(200) DEFAULT '',
		ma_bs			NVARCHAR(20) DEFAULT '',
		kh_son			NVARCHAR(20) DEFAULT '',
		mau_son			NVARCHAR(50) DEFAULT '',
		nha_pp			NVARCHAR(150) DEFAULT '',
		nguon_son		NVARCHAR(10) DEFAULT '',
		sl_son			DECIMAL(19,4) DEFAULT 0,
		ma_hts			NVARCHAR(20) DEFAULT '',
		do_day			NVARCHAR(10) DEFAULT '',
		ngay_giao_hang	SMALLDATETIME DEFAULT '',
		so_ct_lk		NVARCHAR(1000) DEFAULT '',
		lan_xl_loi		INT DEFAULT 0,
		ngay_ct			SMALLDATETIME DEFAULT '',
		dvt				NVARCHAR(20) DEFAULT '',
		dvt_mua			NVARCHAR(20) DEFAULT '',
		sl_dvt_mua		DECIMAL(19,4) DEFAULT 0,
		so_luong		DECIMAL(19,4) DEFAULT 0,
		sl_dat			DECIMAL(19,4) DEFAULT 0,
		sl_dd			DECIMAL(19,4) DEFAULT 0,
		sl_loi			DECIMAL(19,4) DEFAULT 0,
		sl_hong			DECIMAL(19,4) DEFAULT 0,
		ghi_chu			NVARCHAR(255) DEFAULT '',
		loai_hang		NVARCHAR(1) DEFAULT '',
		sl_loi_mma		DECIMAL(19,4) DEFAULT 0,
		dt_kh			DECIMAL(19,4) DEFAULT 0,
		dt_th			DECIMAL(19,4) DEFAULT 0,
		ma_vt			NVARCHAR(20) DEFAULT '',
		ten_dcs			NVARCHAR(255) DEFAULT '',
		ten_htxl		NVARCHAR(255) DEFAULT '',
		ten_hts			NVARCHAR(255) DEFAULT '',
		tl_ht			DECIMAL(19,4) DEFAULT 0,
		cap int DEFAULT 0,
		bold int DEFAULT 0
	)

	-- Xây dựng dữ liệu tạm, lọc mmct theo đk vào bảng #temp
	INSERT INTO #temp (
		ma_cty,
		id_ph,
		ma_ct,
		ngay_lct, 
		str_ngay_lct,
		cuser, 
		so_ct,
		ma_kh, 
		ten_kh_ngan, 
		ma_dcs, 
		ma_htxl, 
		ten_vt,
		ma_bs,
		kh_son,
		mau_son, 
		nha_pp, 
		nguon_son, 
		sl_son,
		ma_hts, 
		do_day,
		ngay_giao_hang,
		so_ct_lk, 
		lan_xl_loi,
		ngay_ct, 
		dvt,
		dvt_mua, 
		sl_dvt_mua, 
		so_luong, 
		sl_dat,
		sl_dd, 
		sl_loi, 
		sl_hong,
		ghi_chu,
		loai_hang,
		sl_loi_mma,
		ma_vt,
		cap, 
		bold)
	SELECT 
		ct.ma_cty,
		ct.id_ph,
		ct.ma_ct,
		ct.ngay_lct, 
		CASE 
			WHEN ct.ngay_lct = '' THEN ''
			ELSE ISNULL(CONVERT(VARCHAR(10), ct.ngay_lct, 103), '')
		END, 
		ct.cuser, 
		ct.so_ct,
		ct.ma_kh, 
		ct.ten_kh_ngan, 
		ct.ma_dcs, 
		ct.ma_htxl, 
		ct.ten_vt,
		ct.ma_bs,
		ct.kh_son,
		ct.mau_son, 
		ct.nha_pp, 
		ct.nguon_son, 
		ct.sl_son,
		ct.ma_hts, 
		ct.do_day,
		ct.ngay_giao,
		ct.so_ct_lk, 
		ct.lan_xl_loi,
		ct.ngay_ct, 
		ct.dvt,
		ct.dvt_mua, 
		ct.sl_dvt_mua, 
		ct.so_luong, 
		ct.sl_dat,
		ct.sl_dd, 
		ct.sl_loi, 
		ct.sl_hong,
		ct.ghi_chu,
		ct.loai_hang,
		ct.sl_loi_mma,
		ct.ma_vt,
		1, 
		0
	FROM MmCt ct
	WHERE ct.ma_cty = @pMa_cty 
		AND ct.ngay_ct BETWEEN @pNgay_ct1 AND @pNgay_ct2
		AND (@pMa_kh = '' OR ct.ma_kh = @pMa_kh)
		AND (@pMa_vt = '' OR ct.ma_vt = @pMa_vt)
		AND (ma_ct = 'MMB' OR (ma_ct = 'MMA' AND id_ph NOT IN (SELECT id_mma FROM MmCt WHERE ma_cty = @pMa_cty)))

	-- Thêm index sau khi insert sẽ tránh việc duy trì index trong quá trình insert
	-- duy trì index: việc duy trì tính bền vững của B+-Tree có thể ảnh hưởng đến hiệu suất khi insert
	CREATE CLUSTERED INDEX idx_temp_cap
	ON #temp (cap, bold)

	-- Thêm dòng tổng theo ngay_ct
	INSERT INTO #temp (
		str_ngay_lct,
		sl_dvt_mua, 
		so_luong, 
		sl_dat, 
		sl_dd,
		sl_loi,
		sl_hong,
		dt_kh,
		dt_th,
		ngay_ct,
		cap,
		bold)
	SELECT 
		N'Cộng:',
		ISNULL(SUM(sl_dvt_mua), 0),
		ISNULL(SUM(so_luong), 0),
		ISNULL(SUM(sl_dat), 0),
		ISNULL(SUM(sl_dd), 0),
		ISNULL(SUM(sl_loi), 0),
		ISNULL(SUM(sl_hong), 0),
		ISNULL(SUM(dt_kh), 0),
		ISNULL(SUM(dt_th), 0),
		ngay_ct,
		1,
		1
	FROM #temp WITH (INDEX(idx_temp_cap))
	WHERE cap = 1 AND bold = 0
	GROUP BY ngay_ct

	-- Thêm dòng tổng tất cả các dòng bôi đỏ
	INSERT INTO #temp (
		str_ngay_lct,
		sl_dvt_mua, 
		so_luong, 
		sl_dat, 
		sl_dd,
		sl_loi,
		sl_hong,
		dt_kh,
		dt_th,
		cap,
		bold)
	SELECT
		N'Tổng cộng:',
		ISNULL(SUM(sl_dvt_mua), 0),
		ISNULL(SUM(so_luong), 0),
		ISNULL(SUM(sl_dat), 0),
		ISNULL(SUM(sl_dd), 0),
		ISNULL(SUM(sl_loi), 0),
		ISNULL(SUM(sl_hong), 0),
		ISNULL(SUM(dt_kh), 0),
		ISNULL(SUM(dt_th), 0),
		2,
		1 
	FROM #temp WITH (INDEX(idx_temp_cap))
	WHERE cap = 1 AND bold = 1

	-- Lấy thông tin báo cáo tổng hợp
	SELECT 
		ISNULL(SUM(sl_son), 0) AS sl_son,
		ISNULL(SUM(CASE WHEN loai_hang = '1' THEN so_luong ELSE 0 END), 0) AS sl_moi,
		ISNULL(SUM(CASE WHEN loai_hang = '3' THEN so_luong ELSE 0 END), 0) AS sl_loi,
		ISNULL(SUM(sl_dat), 0) AS sl_dat,
		ISNULL(
			(
				SELECT TOP 1 ps_co 
				FROM GlCt
				WHERE ma_cty = @pMa_cty 
					AND ngay_ct BETWEEN @pNgay_ct1 AND @pNgay_ct2 
					AND tk LIKE '131%' 
					AND ma_ct = 'sod'
			), 0
		) AS doanh_thu,
		ISNULL(SUM(sl_loi), 0) - ISNULL(SUM(sl_loi_mma), 0) AS sl_loi_con,
		ISNULL(SUM(sl_hong), 0) AS sl_hong
	FROM #temp
	WHERE cap = 1 AND bold = 0

	-- Lấy thông tin chi tiết thực hiện
	SELECT 
		ct.ma_cty,
		ct.id_ph,
		ct.ma_ct,
		ct.ngay_lct AS sdt_ngay_lct,
		ct.str_ngay_lct AS ngay_lct,
		ct.cuser,
		ct.so_ct,
		ct.ten_kh_ngan,
		ct.ma_kh,
		ct.ten_dcs,
		ct.ten_htxl,
		ct.ten_vt,
		ct.ma_bs,
		ct.kh_son,
		ct.mau_son,
		ct.nha_pp,
		ct.nguon_son AS ma_nguon_son,
		CASE ct.nguon_son WHEN 'KH' THEN N'Khách hàng' WHEN 'CTY' THEN N'Công ty' ELSE '' END AS nguon_son,
		ct.sl_son,
		ct.ten_hts,
		ct.do_day,
		ct.ngay_giao_hang,
		ct.so_ct_lk,
		ct.lan_xl_loi,
		ct.ngay_ct,
		ct.dvt,
		ct.dvt_mua,
		ct.sl_dvt_mua,
		ct.so_luong,
		ct.sl_dat,
		ct.sl_dd,
		ct.sl_loi,
		ct.sl_hong,
		ct.tl_ht,
		ct.dt_kh,
		ct.dt_th,
		ct.ghi_chu,
		ct.cap,
		ct.bold
	FROM #temp ct
	ORDER BY cap ASC, ngay_ct ASC, bold ASC

	DROP TABLE #temp
	SET NOCOUNT OFF
GO





