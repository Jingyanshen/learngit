USE [aZaaS.Framework]
GO
/****** Object:  StoredProcedure [dbo].[SP_UserOrgInfomation]    Script Date: 2019/3/31 21:10:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[SP_UserOrgInfomation] 
  (@userCode varchar(100))
AS
BEGIN
   declare @orgid varchar(100)
   select @orgid=zorgid from MDG_Users where ZPERNR=@userCode
   declare @date datetime=getdate()
  ,@ProjectOrgID varchar(100),@ProjectName varchar(100),@ProjectLeader varchar(100)
  ,@CityOrgID varchar(100),@CityName varchar(100),@CityLeader varchar(100),@AreaOrgID varchar(100),@AreaName varchar(100)
  ,@AreaLeader varchar(100),@AreaCoca varchar(100),@AreaAuth varchar(100),@GobbalPath varchar(100)
  ,@ID varchar(100),@Name varchar(100),@levid int,@userName varchar(100),@Coca varchar(100),@Auth varchar(100)
   
    declare vOrgList_cursor cursor scroll for--定义游标用来查询流程的节点
	with Org as 
	( 
		select 1 rowid, case when zbackup3='BGY_NCMDM01' then ZNCORGID else ZORGID end id,ZSPORGID
		from MDG_ORG(nolock) where case when zbackup3='BGY_NCMDM01' then ZNCORGID else ZORGID end=@orgid
		union all 
		select Org.rowid + 1 rowid,case when zbackup3='BGY_NCMDM01' then ZNCORGID else ZORGID end id,d.ZSPORGID from Org 
		inner join MDG_ORG d(nolock) on Org.ZSPORGID = case when zbackup3='BGY_NCMDM01' then ZNCORGID else ZORGID end
	) 
    select Org.id,d.ZORGNAME, zorglev,u.ZNACHN,d.ZAREACOCA,d.ZAuth from Org
	inner join MDG_ORG d(nolock) on case when zbackup3='BGY_NCMDM01' then ZNCORGID else ZORGID end=Org.id
	left join MDG_Users u(nolock) on u.ZPERNR=d.ZSOBID 
	order by Org.rowid
	open vOrgList_cursor
	fetch next from vOrgList_cursor into @ID,@Name,@levid,@userName,@Coca,@Auth
	select @ProjectLeader='',@ProjectOrgID = '',@ProjectName='',@CityLeader='',@CityOrgID='',@CityName='',
	@AreaLeader='',@AreaOrgID='',@AreaName='',@areaCoca='',@AreaAuth='',@GobbalPath=''
	while @@fetch_status=0 
	begin
	   if(@levid=13)
	   begin
	      select @ProjectLeader=@userName,@ProjectOrgID=@ID,@ProjectName=@Name
	   end
	   else if(@levid=12)
	   begin
	      select @CityLeader=@userName,@CityOrgID=@ID,@CityName=@Name
	   end
	   else if(@levid=11)
	   begin
	      select @AreaLeader=@userName,@AreaOrgID=@ID,@AreaName=@Name,@areaCoca=@Coca,@AreaAuth=@Auth
	   end
	   set @GobbalPath=case @GobbalPath when '' then @Name else @GobbalPath+'>'+@Name end
	   fetch next from vOrgList_cursor into @ID,@Name,@levid,@userName,@Coca,@Auth
	end
    close vOrgList_cursor
    DEALLOCATE vOrgList_cursor
	delete from [GlobalOrg] where OrgID=@orgid   
	insert into dbo.[GlobalOrg] values(@orgid,@ProjectOrgID,@ProjectName,@ProjectLeader,@CityOrgID,@CityName,@CityLeader
	,@AreaOrgID,@AreaName,@AreaLeader,@AreaCoca,@AreaAuth,@date,@GobbalPath) 
END
