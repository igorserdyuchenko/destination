CREATE PROCEDURE [dbo].[usp_CableGridGetScheduleItems_Replatform_NEW] --Another version of usp_CableGridGetScheduleItems_Replatform
    @XMLInput XML,
    @CheckOutScheduleNo Varchar(max)=null,
    @UserID VARCHAR(30) = NULL,
    @ReadOnlyUser BIT = '0' --NCM-3555 ReadOnlyUser will be sent as 1 for read-only users

AS
/******************************************************************
NAME: [usp_CableGridGetScheduleItems_Replatform_NEW]
PURPOSE: Get the schedule item details for schedule number
For Monthlygrid load
exec usp_CableGridGetScheduleItems_Replatform_NEW '<ScheduleData>
<ScheduleFilter>
    <Record ScheduleNo="3667" AccessEndDate="11/09/2294"/>
    <Record ScheduleNo="564" AccessEndDate="11/09/2294"/>
    <Record ScheduleNo="38" AccessEndDate="11/09/2294"/>
    <Record ScheduleNo="139035" AccessEndDate="11/09/2294"/>
    <Record ScheduleNo="3882" AccessEndDate="11/09/2294"/>
    <Record ScheduleNo="1659" AccessEndDate="11/09/2294"/>
</ScheduleFilter>
<ScheduleItemFilter>
    <Record/>
</ScheduleItemFilter>
<DOWFilter>
    <Record DOW="0"/>
    <Record DOW="1"/>
    <Record DOW="2"/>
    <Record DOW="3"/>
    <Record DOW="4"/>
    <Record DOW="5"/>
    <Record DOW="6"/>
</DOWFilter>
</ScheduleData>', '139035','206529964','0'

REVISIONS:

Ver     Date[MM-DD-YY]       Author             Description
------  ---------------    ------------         --------------------------
1.0       01/25/2021         Nikitha            1. Created this procedure for NCM-4301 Performance Optimization.

PARAMETERS:
INPUT: None
OUTPUT: Master data
*******************************************************************/
BEGIN
    DECLARE
@ErrNo Int
    --SET NOCOUNT ON             
    SET XACT_ABORT ON
    SET IMPLICIT_TRANSACTIONS OFF

BEGIN TRY
        DECLARE
@XMLInputID INT ,@UserIdName varchar(30),@UserIdNo int, @PeacockNetworkNo int =246
        EXEC SP_XML_PREPAREDOCUMENT @XMLInputID OUTPUT, @XMLInput

CREATE TABLE #Schedule
(
    ScheduleNo          INT,
    DownlinkEnabledFlag CHAR
)
CREATE TABLE #ScheduleItem
(
    StartDate           DATETIME,
    EndDate             DATETIME,
    StartTime           INT,
    EndTime             INT,
    Duration            INT,
    ProgramType         varchar(30),
    MasterSeries        INT,
    ProgramName         VARCHAR(100),
    SeriesName          VARCHAR(200),
    EpisodeName         VARCHAR(200),
    EpisodeNo           varchar(30),
    Version             varchar(30),
    MissingMasterSeries BIT,
    MissingTitle        BIT,
    MissingVersion      BIT,
    FormatNo            INT,
    FormatName          VARCHAR(50),
    SchedProgTypeNo     INT,
    ActualStartTime     INT,
    ActualEndTime       INT,
    ActualDuration      INT,
    DownlinkDate        DATETIME,
    DownlinkStartTime   INT,
    DownlinkDuration    INT,
    DownlinkEndTime     INT
)
CREATE TABLE #DOW
(
    DOW INT
)
--DECLARE @MultiDistributor TABLE(TitleNo INT ,ContractNo INT,PartyName VARCHAR(100))

DECLARE
@CheckoutSchedule TABLE
                                  (
                                      ScheduleNo INT
                                  )


        INSERT INTO #Schedule(ScheduleNo)
SELECT ScheduleNo
FROM OPENXML(@XMLInputID, 'ScheduleData/ScheduleFilter/Record') WITH (ScheduleNo INT)

INSERT
INTO #ScheduleItem(StartDate, EndDate, StartTime, EndTime, Duration, ProgramType, MasterSeries,
                   ProgramName, SeriesName, EpisodeName, EpisodeNo, Version, MissingMasterSeries,
                   MissingTitle, MissingVersion, FormatNo, FormatName, SchedProgTypeNo,
                   ActualStartTime, ActualEndTime, ActualDuration, DownlinkDate, DownlinkStartTime,
                   DownlinkDuration, DownlinkEndTime)
SELECT *
FROM OPENXML(@XMLInputID, 'ScheduleData/ScheduleItemFilter/Record') WITH (StartDate DATETIME, EndDate DATETIME, StartTime INT, EndTime INT, Duration INT, ProgramType varchar (30), MasterSeries INT, ProgramName VARCHAR (100), SeriesName VARCHAR (200), EpisodeName VARCHAR (200), EpisodeNo varchar (30), Version varchar (30), MissingMasterSeries BIT, MissingTitle BIT, MissingVersion BIT, FormatNo INT, FormatName VARCHAR (50), SchedProgTypeNo INT, ActualStartTime INT, ActualEndTime INT, ActualDuration INT, DownlinkDate DATETIME, DownlinkStartTime INT, DownlinkDuration INT, DownlinkEndTime INT)


INSERT
INTO #DOW(DOW)
SELECT DOW
FROM OPENXML(@XMLInputID, 'ScheduleData/DOWFilter/Record') WITH (DOW int)

--Replatform changes for performance improvements
-- below code added to do the modulecheckout update within Db layer instead of service layer Start

select @UserIdNo = UserIdNo
from users
where UserIdNo = @UserID
select @UserIdName = UserId
from users
where UserIdNo = @UserId if (isnull(@CheckOutScheduleNo, '') != '')
begin
INSERT INTO @CheckoutSchedule(ScheduleNo)
select cast(items as int)
from fn_Split(@CheckOutScheduleNo, ',')

Update MC
set Mc.DateCheckedIn=getdate(),
    Mc.UserCheckedIn=@UserIdNo,
    delflag='Y' from modulecheckout MC
                         inner join @CheckoutSchedule CS
on MC.TablePkNo = CS.ScheduleNo
    inner join schedules S on S.scheduleno = CS.scheduleno
    inner join FeedNetwork N
    on N.Networkno = S.Networkno and N.NetworkNo = MC.NetworkNo and N.FeedNo = S.FeedNo
where MC.delflag = 'N'
  and S.delflag = 'N'
  and N.delflag = 'N'
  and N.OpenScheduleFlag != 'Y'
  and MC.ModuleID = 33
delete
from @CheckoutSchedule
end

        declare
@TablePkNo int

        insert into @CheckoutSchedule
select MC.TablePkNo
from #Schedule S
         inner join schedules SC on SC.scheduleno = S.scheduleno
         inner join modulecheckout MC on MC.TablePkNo = S.ScheduleNo
where MC.delflag = 'N'
  and SC.delflag = 'N'-- and MC.ModuleID=33

    if (not exists (select 1 from @CheckoutSchedule) and isnull(@ReadOnlyUser, 0) !=
                                                             1) -- NCM-3555 Added another check on readonlyuser to not insert into ModuleCheckout table if read-only user. (sent from API)
begin

INSERT INTO modulecheckout (ModuleID, TablePkNo, NetworkNo, DateCheckedOut, UserCheckedOut, Delflag)
select 33 as ModuleID, S.scheduleno, N.NetworkNo, getdate(), @UserIdNo, 'N'
from #Schedule S
         inner join schedules SC on SC.scheduleno = S.scheduleno
         inner join FeedNetwork N on N.Networkno = SC.Networkno and N.FeedNo = SC.FeedNo
where N.OpenScheduleFlag != 'Y'
                  and SC.Delflag = 'N'

select MC.ModuleCheckoutNo as ModuleCheckoutNo,
       MC.TablePkNo        as TablePkNo,
       SC.ScheduleName     as ScheduleName,
       MC.ModuleId         as ModuleId,
       null                as UserId,
       null                as UserName,
       N.NetworkName       as NetworkName
from modulecheckout MC
         inner join #Schedule S on S.scheduleno = MC.TablePkNo
         inner join Schedules SC on SC.scheduleno = S.scheduleno
         inner join Networks N on N.Networkno = SC.Networkno and N.NetworkNo = MC.NetworkNo
where SC.Delflag = 'N'
  and MC.ModuleID = 33
  and Mc.DelFlag = 'N'


end
else
begin
select MC.ModuleCheckoutNo as ModuleCheckoutNo,
       MC.TablePkNo        as TablePkNo,
       SC.ScheduleName     as ScheduleName,
       MC.ModuleId         as ModuleId,
       MC.Moduleid,
       MC.UserCheckedOut   as UserId,
       U.Username          as UserName,
       N.NetworkName       as NetworkName
from #Schedule S
         inner join schedules SC on SC.scheduleno = S.scheduleno
         inner join modulecheckout MC on MC.TablePkNo = S.ScheduleNo
         inner join Networks N on N.Networkno = SC.Networkno and N.NetworkNo = MC.NetworkNo
         Inner join USers U on U.useridno = MC.UserCheckedOut
where MC.delflag = 'N'
  and SC.delflag = 'N'
  and N.delflag = 'N'

end
        --  ModuleCheck out End

        --  below code added to do the  select Dynamic Columns within Db layer instead of service layer Start

SELECT distinct 1 as Controls, DisplayDesccription DisplayDescription, TblNetwork.NetworkNo, ColumnName
FROM dbo.ScheduleAttributeNetwork SchedAttNetwork
         INNER JOIN dbo.ScheduleTemplateConfigAttributes SchedTempConfigAttribute
                    ON SchedAttNetwork.ColumnID = SchedTempConfigAttribute.ColumnID
                        AND SchedAttNetwork.DelFlag = 'N' AND SchedTempConfigAttribute.TableID = 1
         INNER JOIN Networks TblNetwork ON TblNetwork.NetworkNo = SchedAttNetwork.NetworkNo
         inner join schedules S on S.NetworkNo = TblNetwork.NetworkNo
         inner join #Schedule TS on TS.ScheduleNo = S.ScheduleNo
where TblNetwork.NetworkNo in (select networkNo from networks where delFlag = 'N' and networkGroupNo in (1, 2))
union
SELECT distinct 2 as Controls, NetworkAttribute.DisplayDesccription, TblNetwork.NetworkNo, ColumnName
FROM dbo.ScheduleTemplateConfigEntity Config
         INNER JOIN dbo.ScheduleTemplateConfigAttributes ConfigAttributes
                    ON Config.TableID = ConfigAttributes.TableID
         INNER JOIN dbo.ScheduleAttributeNetwork NetworkAttribute
                    ON NetworkAttribute.ColumnID = ConfigAttributes.ColumnID AND NetworkAttribute.DelFlag = 'N'
         INNER JOIN Networks TblNetwork ON NetworkAttribute.NetworkNo = TblNetwork.NetworkNo
         inner join schedules S on S.NetworkNo = TblNetwork.NetworkNo
         inner join #Schedule TS on TS.ScheduleNo = S.ScheduleNo
WHERE TableName = 'ScheduleItemCustomProperty'
  AND TblNetwork.NetworkNo in
      (select networkNo from networks where delFlag = 'N' and networkGroupNo in (1, 2))

--Dynamic Columns End
-- Replatform Changes
CREATE INDEX #ScheduleItem_Ind1 ON #ScheduleItem (StartDate, EndDate, StartTime, EndTime, Duration);
CREATE INDEX #DOW_Ind1 On #DOW (DOW)

DECLARE
@ScheduleFeedNo INT, @IsTVEFeedFlag CHAR, @ScheduleNetworkNo INT, @PrimaryFeedNo INT, @TVERightTypeNo INT,@DownlinkEnabledFlag CHAR,@NonNetworkGamePUDID INT
CREATE TABLE #OriginalSchedules
(
    ScheduleNo INT
)
CREATE TABLE #TVESchedules
(
    ScheduleNo INT
) INSERT INTO #OriginalSchedules
SELECT ScheduleNo
FROM #Schedule

CREATE TABLE #AllSchedules
(
    ScheduleNo     INT,
    OLayScheduleNo INT
) INSERT INTO #AllSchedules
SELECT SP.ScheduleNo, ST.ScheduleNo
FROM #Schedule S
         INNER JOIN Schedules ST ON S.ScheduleNo = ST.ScheduleNo AND ST.Delflag = 'N'
         INNER JOIN Feed F ON ST.FeedNo = F.FeedNo AND F.IsPTVEverywhereFeedFlag = 'Y' AND F.Delflag = 'N'
         INNER JOIN Schedules SP ON ST.NetworkNo = SP.NetworkNo AND
                                    ISNULL(ST.CalPeriodNo, -1) = ISNULL(SP.CalPeriodNo, -1) AND
                                    SP.StatusNo = 3 AND SP.ScheduleTypeNo = 2 AND SP.DelFlag = 'N'
         INNER JOIN FeedNetwork FN ON SP.NetworkNo = FN.NetworkNo AND SP.FeedNo = FN.FeedNo AND
                                      FN.IsPrimaryFeedForNetworkFlag = 'Y' AND FN.DelFlag = 'N'
    INSERT
INTO #Schedule (ScheduleNo)
Select ScheduleNo
from #AllSchedules

-- Replatform Changes
CREATE INDEX #Schedule_Ind1 ON #Schedule (ScheduleNo)

Update OSC
Set OSC.DownlinkEnabledFlag = N.DownlinkEnabledFlag FROM #Schedule OSC
                 INNER JOIN Schedules SC
ON SC.ScheduleNo = OSC.ScheduleNo
    INNER JOIN NetWorks N ON N.NetworkNo = SC.NetworkNo
where SC.DelFlag = 'N'
  AND N.DelFlag = 'N'

INSERT
INTO #TVESchedules
SELECT SM.ScheduleNo
FROM #Schedule SM
         LEFT OUTER JOIN #OriginalSchedules OS ON SM.ScheduleNo = OS.ScheduleNo
WHERE OS.ScheduleNo IS NULL


CREATE TABLE #ScheduleItemResult
(
    ScheduleItemNo         INT,
    ScheduleNo             INT,
    ScheduleName           varchar(100),
    ProgramName            VARCHAR(100),
    SeriesNo               INT,
    MasterContract         varchar(250),
    StartDate              varchar(10),
    EndDate                varchar(10),
    SeriesName             VARCHAR(200),
    MasterSeriesNo         INT,
    showcode               varchar(50),
    TitleNo                INT,
    TitleName              VARCHAR(200),
    ContractNo             VARCHAR(50),
    ContractName           VARCHAR(200),
    DelFlag                CHAR(1),
    SeasonName             VARCHAR(200),
    SeasonNo               INT,
    StartTime              varchar(10),
    EndTime                varchar(10),
    ActualStartTime        varchar(20),
    ActualEndTime          varchar(20),
    FeedNo                 INT,
    FeedName               varchar(50),
    AddedUser              VARCHAR(50),
    DateAdded              varchar(25),
    UpdatedUser            VARCHAR(50),
    DateUpdated            varchar(25),
    FeedNetNetworkNo       INT,
    StartDateTime          DATETIME,
    NRCSTitleNo            INT,
    EndDateTime            DATETIME,
    DayOfWeekNo            INT,
    DayOfWeekName          varchar(20),
    SeqNo                  INT,
    SchedProgTypeNo        INT,
    SchedProgType          VARCHAR(50),
    SchedulingType         VARCHAR(50),
    RepeatAirDate          VARCHAR(50),
    ScheduleTypeNo         INT,
    NumberOfGridBlocks     INT,
    ProgramLength          varchar(15),
    BlockDuration          varchar(15),
    NetworkNo              INT,
    ProgramType            VARCHAR(30),
    ProgramTypeNo          INT,
    DistEpisodeID          VARCHAR(30),
    ScheduleDefinitionNo   INT,
    ScheduleDefinitionName varchar(50),
    CommentNo              INT,
    CommentSeq             INT,
    CommentText            VARCHAR(8000),
    SchedCategoryNo        INT,
    SchedCategory          Varchar(30), --ScheduleCategoryNumber INT, --PartyName VARCHAR(100),
    FormatNo               INT,
    FormatName             VARCHAR(50),
    FormatDescription      VARCHAR(Max
) ,
            TitleVersionNo                     INT,
            HouseNo                            VARCHAR(30),
            StereoFlag                         VARCHAR(3),
            CloseCaptionFlag                   VARCHAR(3),
            NRCSURL                            VARCHAR(100),
            NotableEventFlag                   CHAR,
            SpecialEventFlag                   CHAR,
            SubnetBlock                        VARCHAR(1),
            Locked                             CHAR,
            PromoRun                           VARCHAR(1),
            ReadyFlag                          CHAR,
            PrepbyGMOFlag                      CHAR,
            GMOCompletedFlag                   CHAR,
            CrossPlatForm                      CHAR,
            ORFlag                             VARCHAR(50),
            ScheduleChangeEventFlag            CHAR,
            EpisodeNote                        VARCHAR(120),
            LongFormEventFlag                  CHAR,
            InternationalEmbargoedHoursFlag    CHAR,
            TVEEmbargoedHoursFlag              CHAR,
            SiriusXMEmbargoedHoursFlag         CHAR,
            InternationalTVEEmbargoedHoursFlag CHAR,
            RunsRemainingAuditIgnoreFlag       CHAR,
            PGRating                           VARCHAR(100),
            A18_49_Impressions                 VARCHAR(100),
            A25_54_Impressions                 VARCHAR(100),
            TitleType                          VARCHAR(30),
            VersionName                        VARCHAR(30),
            VersionLength                      INT,
            TitleSeriesNo                      INT,
            ActualTitleType                    VARCHAR(30),
            TitleBaseType                      VARCHAR(30), --NCM-4301
            ListValue01                        INT,
            ListValue02                        INT,
            ListValue03                        INT,
            ListValue04                        INT,
            ListValue05                        INT,
            ListValue06                        INT,
            DateTimeValue01                    DATETIME,
            TextValue01                        VARCHAR(Max),
            SwapNetworkNo                      INT,
            IsLockedFlag                       CHAR(1),
            ReleaseYear                        INT,
            DownlinkFlag                       CHAR,
            DownlinkDate                       varchar(10),
            DownlinkStartTime                  varchar(10),
            DownlinkDuration                   varchar(15),
            DownlinkEndTime                    varchar(10),
            DownlinkSource                     INT,
            DownlinkNotes                      VARCHAR(250),
            DownlinkHDFlag                     CHAR,
            DownlinkRecordFlag                 CHAR,
            Bug                                INT,
            Ticker                             INT,
            DESNetwork                         INT,
            SDDelivery                         INT,
            HDDelivery                         INT,
            DBSSpotbeam                        INT,
            BugName                            VARCHAR(100),
            TickName                           VARCHAR(100),
            HDName                             VARCHAR(100),
            SpotbeamName                       VARCHAR(100),
            DownlinkSourceName                 VARCHAR(100),
            SDDeliveryName                     VARCHAR(100),
            DESNetworkName                     VARCHAR(100),
            TitleOwnerNetwork                  VARCHAR(50),
            TVERightPropertyNo                 INT,
            TVEPropertyName                    Varchar(200),
            SchUserAdded                       INT,
            SchUserUpdated                     INT,
            IsReplacementAvailableInTVE        VARCHAR(100),
            NonNetworkGame                     CHAR(1),
            MultipleSelectedID                 varchar(4000),
            StartTime1                         INT,
            StartDate1                         Datetime,
            GTMProductionNo                    VARCHAR(200),
            TMSID                              VARCHAR(200),
            EpisodeNo                          INT,
            otherTitleCaptionName              VARCHAR(200),
            titleCaptionNos                    VARCHAR(4000),
            SeriesTitleNo                      INT,
            FormatGuid                         VARCHAR(100)
        ) INSERT INTO #ScheduleItemResult(ScheduleItemNo, ScheduleNo, ScheduleName, ProgramName, SeriesNo, MasterContract,
                                        StartDate, EndDate, SeriesName, MasterSeriesNo, showcode, TitleNo, TitleName,
                                        ContractNo, ContractName, DelFlag,
                                        SeasonName, SeasonNo, StartTime, EndTime, ActualStartTime, ActualEndTime,
                                        FeedNo, FeedName, AddedUser, DateAdded, UpdatedUser, DateUpdated,
                                        FeedNetNetworkNo,-- StartDateTime,
                                        NRCSTitleNo, --EndDateTime,
                                        DayOfWeekNo, DayOfWeekName, SeqNo, SchedProgTypeNo, SchedProgType,
                                        SchedulingType,
                                        RepeatAirDate, ScheduleTypeNo, NumberOfGridBlocks, ProgramLength, BlockDuration,
                                        NetworkNo, ProgramType, ProgramTypeNo, DistEpisodeID, ScheduleDefinitionNo,
                                        ScheduleDefinitionName,
                                        CommentNo, CommentSeq, CommentText, SchedCategoryNo, SchedCategory,-- ScheduleCategoryNumber,-- PartyName,
                                        FormatNo, FormatName, FormatDescription, TitleVersionNo,
                                        HouseNo, StereoFlag, CloseCaptionFlag, NRCSURL, NotableEventFlag,
                                        SpecialEventFlag, SubnetBlock,
                                        Locked, PromoRun, ReadyFlag, PrepbyGMOFlag, GMOCompletedFlag, CrossPlatForm,
                                        ORFlag, ScheduleChangeEventFlag, EpisodeNote, LongFormEventFlag,
                                        InternationalEmbargoedHoursFlag, TVEEmbargoedHoursFlag,
                                        SiriusXMEmbargoedHoursFlag, InternationalTVEEmbargoedHoursFlag,
                                        RunsRemainingAuditIgnoreFlag, PGRating,
                                        A18_49_Impressions, A25_54_Impressions, TitleType, VersionName, VersionLength,
                                        TitleSeriesNo, ActualTitleType,
                                        TitleBaseType, --NCM-4301
                                        ListValue01, ListValue02, ListValue03, ListValue04, ListValue05, ListValue06,
                                        DateTimeValue01, TextValue01, SwapNetworkNo, IsLockedFlag, ReleaseYear,
                                        DownlinkFlag, DownlinkDate, DownlinkStartTime,
                                        DownlinkDuration, DownlinkEndTime, DownlinkSource, DownlinkNotes,
                                        DownlinkHDFlag, DownlinkRecordFlag, Bug, Ticker, DESNetwork, SDDelivery,
                                        HDDelivery, DBSSpotbeam
            , BugName, TickName, HDName, SpotbeamName, DownlinkSourceName, SDDeliveryName, DESNetworkName
            , TitleOwnerNetwork, TVERightPropertyNo, TVEPropertyName, SchUserAdded, SchUserUpdated,
                                        IsReplacementAvailableInTVE, MultipleSelectedID, StartTime1, StartDate1,
                                        GTMProductionNo,
                                        TMSID, EpisodeNo, otherTitleCaptionName, titleCaptionNos, SeriesTitleNo,
                                        FormatGuid)

SELECT SchedItem.SchedItemNo                                                           ScheduleItemNo,
       Schedule.ScheduleNo,
       Schedule.ScheduleName,
       SchedItem.ProgramName,
       SchedItem.SeriesNo,
       MC.MasterContract                                  as                           MasterContract,
       convert(varchar (10), cast(SchedItem.StartDate as date), 101)                   StartDate,
       convert(varchar (10), cast(SchedItem.EndDate as date), 101)                     EndDate,
       Series.TitleName                                                                SeriesName,
       Title.seriesNo                                     as                           MasterSeriesNo,
       Title.ShowID,
       SchedItem.TitleNo,
       Title.TitleName                                                                 TitleName,
       CH.ContractNo,
       CH.ContractName,
       Title.DelFlag,
       CASE
           WHEN Schedule.NetworkNo = @PeacockNetworkNo THEN ParentSeries.TitleName
           ELSE Season.SeasonName END                                                  SeasonName,    --NCM-3870 Peacock n/w season name changes
       Season.SeasonNo,
       dbo.[fn_sec_tostr_time_byNetwork](SchedItem.StartTime, Schedule.NetworkNo, Schedule.FeedNo) StartTime1, dbo.[fn_sec_tostr_time_byNetwork](CASE WHEN SchedItem.EndTime = 0 THEN 86400 else SchedItem.EndTime end,
                                                 Schedule.NetworkNo, Schedule.FeedNo)                      EndTime, dbo.fn_GetSecondsToTimeByNetwork(
        SchedItem.ActualStartTime, Schedule.NetworkNo,
        Schedule.FeedNo) ActualStartTime,
       dbo.fn_GetSecondsToTimeByNetwork(
               CASE WHEN SchedItem.ActualEndTime = 0 THEN 86400 else SchedItem.ActualEndTime end,
               Schedule.NetworkNo,
               Schedule.FeedNo)                                                        ActualEndTime,
       Schedule.FeedNo,
       F.FeedName,
       NULL                                               As                           AddedUser,
       CONVERT(VARCHAR (10), SchedItem.DateAdded, 101) + ' ' +
       substring(convert(varchar (20), SchedItem.DateAdded, 9), 13, 8) + ' ' +
       substring(convert(varchar (30), SchedItem.DateAdded, 9), 25, 2)                 DateAdded,
       NULL                                               As                           UpdatedUser,
       CONVERT(VARCHAR (10), SchedItem.DateUpdated, 101) + ' ' +
       substring(convert(varchar (20), SchedItem.DateUpdated, 9), 13, 8) + ' ' +
       substring(convert(varchar (30), SchedItem.DateUpdated, 9), 25, 2)               DateUpdated,
       FeedNet.NetworkNo,
       --dbo.GetDateTime(FeedNet.ScheduleStartHour, SchedItem.StartDate, SchedItem.StartTime) StartDateTime,
       SchedItem.NRCSTitleNo,
       --dbo.GetDateTime(FeedNet.ScheduleStartHour, SchedItem.EndDate,CASE WHEN SchedItem.EndTime = 0 THEN 86400 ELSE SchedItem.EndTime END) EndDateTime,
       SchedItem.DayOfWeekNo,
       case
           when SchedItem.DayOfWeekNo = 0 then 'Monday'
           when SchedItem.DayOfWeekNo = 1 then 'Tuesday'
           when SchedItem.DayOfWeekNo = 2 then 'Wednesday'
           when SchedItem.DayOfWeekNo = 3 then 'Thursday'
           when SchedItem.DayOfWeekNo = 4 then 'Friday'
           when SchedItem.DayOfWeekNo = 5 then 'Saturday'
           when SchedItem.DayOfWeekNo = 6
               then 'Sunday' end                                                       DayOfWeekName,

       SchedItem.SeqNo,
       ProgType.SchedProgTypeNo,
       ProgType.SchedProgType,
       ProgType.SchedProgType                                                          SchedulingType,
       SchedItem.RepeatAirDate,
       ProgType.ScheduleTypeNo,
       SchedItem.NoOfGridBlocks                                                        NumberOfGridBlocks,
       dbo.fn_sec_tostr_HHMMSS(Schedule.NetworkNo, CASE
                                                       WHEN SchedItem.ActualEndTime = 0 THEN 86400
                                                       else SchedItem.ActualEndTime end -
                                                   SchedItem.ActualStartTime)          ProgramLength,
       dbo.fn_sec_tostr_HH_MM((CASE WHEN SchedItem.EndTime = 0 THEN 86400 else SchedItem.EndTime end -
                               SchedItem.StartTime))      AS                           BlockDuration,
       Schedule.NetworkNo,
       SchedItem.ProgramType,
       TTY.TitleTypeNo,
       Title.DistEpisodeID,
       SchedItem.ScheduleDefinitionNo,
       SD.ScheduleDefinitionName,
       Comment.CommentNo,
       Comment.CommentSeq,
       Comment.CommentText,
       SchedItem.SchedCategoryNo,
       SchedCategory,
       SchedItem.FormatNo,
       SchedItem.FormatName,
       Format.Comments,
       CASE
           WHEN TitleVersion.TitleVersionNo IS NULL THEN -1
           ELSE TitleVersion.TitleVersionNo END                                        TitleVersionNo,
       TitleVersion.HouseNo,
       TitleVersion.StereoFlag,
       TitleVersion.CloseCaptionFlag,
       TitleVersion.NRCSURL,
       case when SchedItem.NotableEventFlag = 'Y' then '1' ELSE '0' end                NotableEventFlag,
       case when SchedItem.SpecialEventFlag = 'Y' then '1' ELSE '0' end                SpecialEventFlag,
       case when SchedItem.SubnetBlock = 'Y' then '1' ELSE '0' end                     SubnetBlock,
       case when SchedItem.Locked = 'Y' then '1' ELSE '0' end                          Locked,
       case when SchedItem.PromoRun = 'Y' then '1' ELSE '0' end                        PromoRun,
       case when SchedItem.ReadyFlag = 'Y' then '1' ELSE '0' end                       ReadyFlag,
       case when SchedItem.PrepbyGMOFlag = 'Y' then '1' ELSE '0' end                   PrepbyGMOFlag,
       case when SchedItem.GMOCompletedFlag = 'Y' then '1' ELSE '0' end                GMOCompletedFlag,
       case when SchedItem.CrossPlatform = 'Y' then '1' ELSE '0' end                   CrossPlatForm,
       SchedItem.ORFlag,
       case when SchedItem.ScheduleChangeEventFlag = 'Y' then '1' ELSE '0' end         ScheduleChangeEventFlag,
       SchedItem.EpisodeNote,
       case when SchedItem.LongFormEventFlag = 'Y' then '1' ELSE '0' end               LongFormEventFlag,
       case
           when SchedItem.InternationalEmbargoedHoursFlag = 'Y' then '1'
           ELSE '0' end                                                                InternationalEmbargoedHoursFlag,
       case when SchedItem.TVEEmbargoedHoursFlag = 'Y' then '1' ELSE '0' end           TVEEmbargoedHoursFlag,
       case when SchedItem.SiriusXMEmbargoedHoursFlag = 'Y' then '1' ELSE '0' end      SiriusXMEmbargoedHoursFlag,
       case
           when SchedItem.InternationalTVEEmbargoedHoursFlag = 'Y' then '1'
           ELSE '0' end                                                                InternationalTVEEmbargoedHoursFlag,
       case
           when SchedItem.RunsRemainingAuditIgnoreFlag = 'Y' then '1'
           ELSE '0' end                                                                RunsRemainingAuditIgnoreFlag,
       TitleVersion.PGRating,
       NULL                                                                            A18_49_Impressions,
       NULL                                                                            A25_54_Impressions,
       Title.TitleType,
       SchedItem.VersionName,
       SchedItem.VersionLength,
       ParentSeries.SeriesNo                              AS                           TitleSeriesNo,
       ParentSeries.TitleType                             AS                           ActualTitleType,
       TitleType.TitleBaseType                            as                           TitleBaseType, -- NCM-4301
       ListValue01,
       ListValue02,
       ListValue03,
       ListValue04,
       ListValue05,
       ListValue06,
       DateTimeValue01,
       TextValue01,
       SchedItem.SwapNetworkNo,
       case when SchedItem.IsLockedFlag = 'Y' then '1' ELSE '0' end                    IsLockedFlag,
       CASE
           WHEN TitleType.DisplayReleaseYearInPreferenceFlag = 'Y' Then Title.ReleaseYear
           ELSE 0 END                                                                  ReleaseYear,
       case when SchedItem.DownlinkFlag = 'Y' then '1' ELSE '0' end                    DownlinkFlag,
       convert(varchar (10), cast(SchedItem.DownlinkDate as date), 101)                DownlinkDate,
       --SchedItem.DownlinkStartTime,
       case
           when CHARINDEX(':', dbo.fn_sec_tostr_AMPM_12(SchedItem.DownlinkStartTime)) = 2 then '0' +
                                                                                               dbo.fn_sec_tostr_AMPM_12(case
                                                                                                                            when SchedItem.DownlinkStartTime = -1
                                                                                                                                then null
                                                                                                                            else SchedItem.DownlinkStartTime end)
           else dbo.fn_sec_tostr_AMPM_12(case
                                             when
                                                 SchedItem.DownlinkStartTime = -1 then null
                                             else SchedItem.DownlinkStartTime end) end DownlinkStartTime,
       dbo.fn_sec_tostr_HH_MM(case
                                  when SchedItem.DownlinkDuration = -1 then null
                                  else SchedItem.DownlinkDuration end)                 DownlinkDuration,
       --SchedItem.DownlinkEndTime,
       case
           when CHARINDEX(':', dbo.fn_sec_tostr_AMPM_12(SchedItem.DownlinkEndTime)) = 2 then '0' +
                                                                                             dbo.fn_sec_tostr_AMPM_12(case
                                                                                                                          when SchedItem.DownlinkEndTime = -1
                                                                                                                              then null
                                                                                                                          else SchedItem.DownlinkEndTime end)
           else dbo.fn_sec_tostr_AMPM_12(case
                                             when SchedItem.DownlinkEndTime = -1 then null
                                             else SchedItem.DownlinkEndTime end) end   DownlinkEndTime,
       SchedItem.DownlinkSource,
       SchedItem.DownlinkNotes,
       case when SchedItem.DownlinkHDFlag = 'Y' then '1' ELSE '0' end                  DownlinkHDFlag,
       case when SchedItem.DownlinkRecordFlag = 'Y' then '1' ELSE '0' end              DownlinkRecordFlag,
       SchedItem.Bug,
       SchedItem.Ticker,
       SchedItem.Network,
       SchedItem.SDDelivery,
       SchedItem.HDDelivery,
       SchedItem.DBSSpotbeam,
       BUG.PropertyListValue                              as                           BugName,
       TIC.PropertyListValue                                                           TickName,
       HD.PropertyListValue                               as                           HDName,
       SPO.PropertyListValue                              as                           SpotbeamName,
       SOR.PropertyListValue                              as                           DownlinkSourceName,
       SDD.PropertyListValue                              as                           SDDeliveryName,
       DE.PropertyListValue                               as                           DESNetworkName,
       N.NetworkName                                      AS                           TitleOwnerNetwork,
       SchedItem.TVEStatus                                AS                           TVERightPropertyNo,
       TRP.TVERightPropertyShortName                      as                           TVEPropertyName,
       SchedItem.UserAdded,
       SchedItem.UserUpdated,
       Case
           when IsNull(SchedItem.IsReplacementAvailableInTVE, '') = '' THEN 'N'
           ELSE SchedItem.IsReplacementAvailableInTVE END AS                           IsReplacementAvailableInTVE
        ,
       SchedItem.MultipleSelectedID,
       SchedItem.StartTime,
       SchedItem.StartDate,
       ADTD.GTMProductionNo,
       ADTD.TMSID,
       ADTD.PeacockEpisodeNo                              AS                           EpisodeNo,
       SchedItem.otherTitleCaption,
       SchedItem.MultipleSelectedID,
       SchedItem.SeriesTitleNo,
       FormatGuid
FROM dbo.Schedules Schedule
         INNER JOIN #Schedule TempSchedule ON Schedule.ScheduleNo = TempSchedule.ScheduleNo
         INNER JOIN dbo.FeedNetwork FeedNet
                    ON Schedule.FeedNo = FeedNet.FeedNo AND Schedule.NetworkNo = FeedNet.NetworkNo
         INNER JOIN dbo.ScheduleItem SchedItem ON SchedItem.ScheduleNo = Schedule.ScheduleNo
         INNER JOIN #DOW DOW ON (SchedItem.DayOfWeekNo = DOW.DOW OR DOW.DOW IS NULL)
    --LEFT OUTER JOIN Users UserAdded ON SchedItem.UserAdded = UserAdded.UserIdNo
    --LEFT OUTER JOIN Users UserUpdated ON SchedItem.UserUpdated = UserUpdated.UserIdNo
         INNER JOIN #ScheduleItem TempBulkSchedules ON
    SchedItem.StartDate >= ISNULL(TempBulkSchedules.StartDate, SchedItem.StartDate) AND
    SchedItem.EndDate <= ISNULL(TempBulkSchedules.EndDate, SchedItem.EndDate)
        AND (
        (
            (
                SchedItem.StartTime BETWEEN ISNULL(TempBulkSchedules.StartTime, SchedItem.StartTime) AND ISNULL(TempBulkSchedules.EndTime, SchedItem.StartTime)
                    OR
                SchedItem.EndTime BETWEEN ISNULL(TempBulkSchedules.StartTime, SchedItem.EndTime) AND ISNULL(TempBulkSchedules.EndTime, SchedItem.EndTime)
                    OR
                (SchedItem.StartTime = 0 AND SchedItem.EndTime = 0)
                )
                AND SchedItem.StartTime <= ISNULL(TempBulkSchedules.EndTime, SchedItem.StartTime)
                AND
            (
                (
                    SchedItem.EndTime <> ISNULL(TempBulkSchedules.StartTime, SchedItem.StartTime) AND
                    SchedItem.StartTime <> ISNULL(TempBulkSchedules.EndTime, SchedItem.EndTime)
                    )
                    OR
                (
                    SchedItem.StartTime = SchedItem.EndTime AND SchedItem.EndTime = 0
                    )
                )
            )
            OR
        (
            TempBulkSchedules.StartTime Is Not Null And TempBulkSchedules.EndTime Is Not Null And
            TempBulkSchedules.StartTime > SchedItem.StartTime And TempBulkSchedules.EndTime < SchedItem.EndTime
            )
        )
        AND (
        (
            (
                SchedItem.ActualStartTime BETWEEN ISNULL(TempBulkSchedules.ActualStartTime, SchedItem.ActualStartTime) AND ISNULL(TempBulkSchedules.ActualEndTime, SchedItem.ActualStartTime)
                    OR
                SchedItem.ActualEndTime BETWEEN ISNULL(TempBulkSchedules.ActualStartTime, SchedItem.ActualEndTime) AND ISNULL(TempBulkSchedules.ActualEndTime, SchedItem.ActualEndTime)
                    OR
                (SchedItem.ActualStartTime = 0 AND SchedItem.ActualEndTime = 0)
                )
                AND
            SchedItem.ActualStartTime <= ISNULL(TempBulkSchedules.ActualEndTime, SchedItem.ActualStartTime)
                AND
            (
                (
                    SchedItem.ActualEndTime <>
                    ISNULL(TempBulkSchedules.ActualStartTime, SchedItem.ActualStartTime) AND
                    SchedItem.ActualStartTime <>
                    ISNULL(TempBulkSchedules.ActualEndTime, SchedItem.ActualEndTime)
                    )
                    OR
                (
                    SchedItem.ActualStartTime = SchedItem.ActualEndTime --AND SchedItem.ActualEndTime=0
                    )
                )
            )
            OR
        (
            TempBulkSchedules.ActualStartTime Is Not Null And TempBulkSchedules.ActualEndTime Is Not Null And
            TempBulkSchedules.ActualStartTime > SchedItem.ActualStartTime And
            TempBulkSchedules.ActualEndTime < SchedItem.ActualEndTime
            )
        )
        AND
    ((TempSchedule.DownlinkEnabledFlag = 'N')
        OR
     (
         (
             (
                 SchedItem.DownlinkStartTime BETWEEN ISNULL(TempBulkSchedules.DownlinkStartTime,
                                                            SchedItem.DownlinkStartTime) AND ISNULL(
                         TempBulkSchedules.DownlinkEndTime, SchedItem.DownlinkStartTime)
                     OR
                 SchedItem.DownlinkEndTime BETWEEN ISNULL(TempBulkSchedules.DownlinkStartTime,
                                                          SchedItem.DownlinkEndTime) AND ISNULL(TempBulkSchedules.DownlinkEndTime, SchedItem.DownlinkEndTime)
                     OR
                 (SchedItem.DownlinkStartTime = 0 AND SchedItem.DownlinkEndTime = 0)
                 )
                 AND SchedItem.DownlinkStartTime <=
                     ISNULL(TempBulkSchedules.DownlinkEndTime, SchedItem.DownlinkStartTime)
                 AND
             (
                 (
                     SchedItem.DownlinkEndTime <>
                     ISNULL(TempBulkSchedules.DownlinkStartTime, SchedItem.DownlinkStartTime) AND
                     SchedItem.DownlinkStartTime <>
                     ISNULL(TempBulkSchedules.DownlinkEndTime, SchedItem.DownlinkEndTime)
                     )
                     OR
                 (
                     SchedItem.DownlinkStartTime = SchedItem.DownlinkEndTime
                     )
                 )
             )
             OR
         (
             TempBulkSchedules.DownlinkStartTime Is Not Null And
             TempBulkSchedules.DownlinkEndTime Is Not Null And
             TempBulkSchedules.DownlinkStartTime > SchedItem.DownlinkStartTime And
             TempBulkSchedules.DownlinkEndTime < SchedItem.DownlinkEndTime
             )
         )
        )
        AND (TempBulkSchedules.Duration IS NULL OR
             (SchedItem.EndTime - SchedItem.StartTime) = TempBulkSchedules.Duration)
        AND (TempBulkSchedules.ActualDuration IS NULL OR
             (SchedItem.ActualEndTime - SchedItem.ActualStartTime) = TempBulkSchedules.ActualDuration)
        AND (TempBulkSchedules.DownlinkDuration IS NULL OR
             (SchedItem.DownlinkEndTime - SchedItem.DownlinkStartTime) = TempBulkSchedules.DownlinkDuration)
        AND
    (TempBulkSchedules.DownlinkDate IS NULL OR (SchedItem.DownlinkDate = TempBulkSchedules.DownlinkDate))
        AND ((TempBulkSchedules.MasterSeries IS NULL) OR (SchedItem.SeriesNo = TempBulkSchedules.MasterSeries))
        AND
    ((TempBulkSchedules.MissingTitle IS NULL OR TempBulkSchedules.MissingTitle = 0) OR (SchedItem.TitleNo = -1))
        AND ((TempBulkSchedules.MissingVersion IS NULL OR TempBulkSchedules.MissingVersion = 0) OR
             (SchedItem.TitleVersionNo = -1))
         LEFT OUTER JOIN dbo.SchedProgType ProgType
                         ON SchedItem.SchedProgTypeNo = ProgType.SchedProgTypeNo AND ProgType.DelFlag = 'N'
         LEFT OUTER JOIN dbo.Titles Title ON SchedItem.TitleNo = Title.TitleNo AND Title.DelFlag = 'N'
         LEFT OUTER JOIN dbo.ContractHeaders CH
                         on CH.ContractNo = Title.ContractNo and CH.DelFlag = 'N' -- CM-4755
         LEFT OUTER JOIN dbo.Titles Series
                         ON SchedItem.SeriesNo = Series.TitleNo --AND Series.DelFlag = 'N'
         LEFT OUTER JOIN dbo.Titles ParentSeries
                         ON ParentSeries.TitleNo = Title.SeriesNo AND ParentSeries.DelFlag = 'N'
         LEFT OUTER JOIN dbo.SchedItemComments SchedComments
                         ON SchedComments.SchedItemNo = SchedItem.SchedItemNo AND
                            SchedComments.DayOfWeekNo = SchedItem.DayOfWeekNo AND
                            SchedComments.SeqNo = SchedItem.SeqNo
         LEFT OUTER JOIN dbo.Comments Comment
                         ON SchedComments.CommentNo = Comment.CommentNo AND Comment.DelFlag = 'N'
    --LEFT OUTER JOIN dbo.ContractDistributor ContractDist ON Title.ContractNo = ContractDist.ContractNo AND ContractDist.DelFlag = 'N'
         LEFT OUTER JOIN dbo.TitleVersions TitleVersion
                         ON TitleVersion.TitleVersionNo = SchedItem.TitleVersionNo AND
                            TitleVersion.DelFlag = 'N'
         LEFT OUTER JOIN dbo.vw_NetworkTitleType TitleType ON SchedItem.ProgramType = TitleType.TitleType AND
                                                              TitleType.NetworkNo = Schedule.NetworkNo AND
                                                              TitleType.Delflag = 'N'
         LEFT OUTER JOIN dbo.Seasons Season ON Title.SeasonNo = Season.SeasonNo
         LEFT OUTER JOIN dbo.Formats Format ON SchedItem.FormatName = Format.FormatName AND
                                               Schedule.NetworkNo = Format.NetworkNo AND Format.DelFlag = 'N'
         LEFT OUTER JOIN dbo.[fn_get_AccessWeekBookandUnBookedForUser](@UserIdName) FA
ON FA.ModuleNetworkNo = Schedule.NetworkNo AND FA.AspectName = 'Future Access Days'
    LEFT OUTER JOIN TitleNetworks TN ON Title.TitleNo = TN.TitleNo AND TN.OwnerNetworkFlag = 'Y'
    LEFT OUTER JOIN NetWorks N
    ON TN.NetworkNo = N.NetworkNo AND TN.OwnerNetworkFlag = 'Y' AND N.DelFlag = 'N' AND
    TN.DelFlag = 'N'
    --Replatform changes for performance improvements
    LEFT OUTER JOIN schedulecategory SC ON SchedItem.SchedCategoryNo = SC.SchedCategoryNo
    LEFT OUTER JOIN ScheduleDefinition SD on SD.ScheduleDefinitionNo = SchedItem.ScheduleDefinitionNo
    LEFT OUTER JOIN Feed F ON F.FeedNo = Schedule.FeedNo
    LEFT OUTER JOIN vw_NetworkTitleType TTY ON TTY.NetworkNo = Schedule.NetworkNo AND TTY.Delflag = 'N' and
    TTY.titleType <> 'EPISODE' and
    TTY.TitleType = SchedItem.ProgramType
    LEFT OUTER JOIN TVERightProperty TRP on SchedItem.TVEStatus = TRP.TVERightPropertyNo
    LEFT OUTER JOIN PropertyListValue BUG on BUG.PropertyListValueID = SchedItem.Bug
    LEFT OUTER JOIN PropertyListValue TIC on TIC.PropertyListValueID = SchedItem.Ticker
    LEFT OUTER JOIN PropertyListValue HD on HD.PropertyListValueID = SchedItem.HDDelivery
    LEFT OUTER JOIN PropertyListValue SPO on SPO.PropertyListValueID = SchedItem.DBSSpotbeam
    LEFT OUTER JOIN PropertyListValue SOR on SOR.PropertyListValueID = SchedItem.DownlinkSource
    LEFT OUTER JOIN PropertyListValue SDD on SDD.PropertyListValueID = SchedItem.SDDelivery
    LEFT OUTER JOIN PropertyListValue DE on DE.PropertyListValueID = SchedItem.Network
    LEFT JOIN MasterContracts MC on MC.MasterContractNo = CH.MasterContractNo AND MC.DelFlag = 'N'
    LEFT OUTER JOIN AdditionalDTCTitleData ADTD ON ADTD.TitleNo = Title.TitleNo AND ADTD.DelFlag = 'N'
WHERE Schedule.DelFlag = 'N'
  AND FeedNet.DelFlag = 'N'
  AND ((TempBulkSchedules.Version IS NULL)
   OR
    (ISNULL(TitleVersion.HouseNo
    , '') like '%' + TempBulkSchedules.Version + '%'))
  AND (TempBulkSchedules.ProgramType IS NULL
   OR SchedItem.ProgramType = TempBulkSchedules.ProgramType)
  AND ((TempBulkSchedules.ProgramName IS NULL)
   OR
    (SchedItem.ProgramName like '%' + TempBulkSchedules.ProgramName + '%'))
  AND ((TempBulkSchedules.EpisodeNo IS NULL)
   OR
    (ISNULL(Title.DistEpisodeID
    , '') = TempBulkSchedules.EpisodeNo)
   OR
    (FeedNet.NetworkNo = @PeacockNetworkNo
  AND
    (CONVERT (VARCHAR
    , ISNULL(ADTD.PeacockEpisodeNo
    , ''))) = TempBulkSchedules.EpisodeNo)) --NCM-361
--7 changes for Peacock network
--OR ((TempBulkSchedules.EpisodeNo IS NULL) OR (ISNULL(ADTD.PeacockEpisodeNo,'') = TempBulkSchedules.EpisodeNo))  --NCM-3617 changes for Peacock network
  AND ((TempBulkSchedules.EpisodeName IS NULL)
   OR (Title.TitleName like '%'+ TempBulkSchedules.EpisodeName +'%'))
  AND ((TempBulkSchedules.SeriesName IS NULL)
   OR (ISNULL(ParentSeries.TitleName
    , '') like '%'+ TempBulkSchedules.SeriesName +'%'))
  AND ((TempBulkSchedules.FormatName IS NULL)
   OR (TempBulkSchedules.FormatName = SchedItem.FormatName))
  AND ((TempBulkSchedules.SchedProgTypeNo IS NULL)
   OR (TempBulkSchedules.SchedProgTypeNo = ProgType.SchedProgTypeNo))
  AND ((TempBulkSchedules.MissingMasterSeries IS NULL
   or TempBulkSchedules.MissingMasterSeries=0)
   OR ((SchedItem.SeriesNo = -1
  AND TitleType.TitleBaseType = 'E')
   OR ((SchedItem.ProgramType IS NULL
   OR SchedItem.ProgramType = '')
  AND SchedItem.TitleNo= -1
  AND SchedItem.SeriesNo=-1 )))
--AND  (ISNULL(PermissionLevelValue,'0')='0' OR SchedItem.StartDate<=(DATEADD(DAY,((CONVERT(INT,FA.PermissionLevelValue))),GETDATE())))
  AND SchedItem.StartDate<=(DATEADD(DAY
    , ((CONVERT (INT
    , ISNULL(PermissionLevelValue
    , '0'))))
    , GETDATE()))
ORDER BY SchedItem.StartDate, SchedItem.DayOfWeekNo, SchedItem.StartTime

SELECT @ScheduleNetworkNo = FeedNetNetworkNo
FROM #ScheduleItemResult
SELECT @NonNetworkGamePUDID = PUD.PropertyUsageDefinitionID
FROM PropertyUsageDefinition PUD
         INNER JOIN Properties P ON P.PropertyID = PUD.PropertyID AND P.DelFlag = 'N' AND PUD.DelFlag = 'N'
WHERE PUD.NetworkNo = @ScheduleNetworkNo
  AND PUD.[Level] = 'Episodes'
  AND P.PropertyName = 'Non-network Game'

-- Replatform Changes
CREATE INDEX #ScheduleItemResult_ind1 on #ScheduleItemResult (ScheduleNo, TitleNo)
--Replatform changes for performance improvements
select distinct TV.Titleno, TV.TitleVersionNo, TV.HouseNo, TV.VersionLength, VerDescription
from #ScheduleItemResult SR
         inner join TitleVersions TV on TV.titleno = SR.TitleNo
where SR.TitleNo != -1
          and TV.DelFlag = 'N'


        IF @NonNetworkGamePUDID IS NOT NULL
BEGIN
UPDATE S
SET S.NonNetworkGame = P.BooleanValue FROM #ScheduleItemResult S
                         LEFT OUTER JOIN dbo.PropertyValueMapping P
ON P.TitleNo = S.TitleNo
WHERE P.PropertyUsageDefinitionID = @NonNetworkGamePUDID
  AND P.DelFlag = 'N'
END

UPDATE #ScheduleItemResult
SET NonNetworkGame = ISNULL(NonNetworkGame, 'N')

Update s
set AddedUser = U.UserName FROM #ScheduleItemResult s
                 INNER JOIN Users U
ON s.SchUserAdded = U.UserIdNo

Update s
set UpdatedUser = U.UserName FROM #ScheduleItemResult s
                 INNER JOIN Users U
ON s.SchUserUpdated = U.UserIdNo
    IF EXISTS (SELECT 1 FROM #TVESchedules)
BEGIN

                DECLARE
@ScheduleRightTypeNo INT, @TVEFeedNo INT
                DECLARE
@PartnerNo INT,@PartnerTypeNo INT,@NetworkNo INT

SELECT DISTINCT @TVEFeedNo = S.FeedNo, @NetworkNo = S.NetworkNo
FROM Schedules S
         INNER JOIN #OriginalSchedules OS ON S.ScheduleNo = OS.ScheduleNo IF NOT EXISTS(SELECT 1 FROM dbo.TVERightTypeFeed WHERE FeedNo = @TVEFeedNo)
BEGIN

                        DECLARE
@TitleRights TABLE
                                             (
                                                 TitleNo          INT,
                                                 OverrideStatus   VARCHAR(100),
                                                 NetworkNo        INT,
                                                 TVEPartnerTypeNo INT,
                                                 TVEPartnerNo     INT,
                                                 StatusRule       VARCHAR(100),
                                                 ExceptionMessage VARCHAR(8000)
                                             )

SELECT @PartnerNo = TVEPartnerNo, @PartnerTypeNo = TVEPartnerTypeNo
FROM dbo.TVEPartner
WHERE FeedNo = @TVEFeedNo

Declare
@schedulelist varchar(max)=null
                        Set @schedulelist = RTRIM(STUFF(
                                (SELECT ',' + convert(varchar(100), ScheduleNo) FROM #Schedule FOR XML PATH('')), 1, 1,
                                ''))
                        INSERT INTO @TitleRights EXEC usp_GetTitleRulesDetails @NetworkNo, @PartnerNo, @PartnerTypeNo,
                                                      null, null, null, null, @schedulelist

                        -- REplatform Changes -- Debug Message
                        --Select count(*) as TitleRightsCount from @TitleRights
                        --Select count(*) as FinalScheduleItemResultCount from #FinalScheduleItemResult
                        --Select count(*) as TVESchedulesCount from #TVESchedules
                        --Select count(*) as TitleRightsCount from @TitleRights


SELECT SIR.*, ISNULL(StatusRule, 'Y') as StatusRule, ExceptionMessage
into #FinalScheduleItemResult
FROM #ScheduleItemResult SIR
         INNER JOIN #TVESchedules TS ON SIR.ScheduleNo = TS.ScheduleNo
         LEFT OUTER JOIN @TitleRights TR
                         ON SIR.TitleNo = TR.TitleNo AND SIR.NetworkNo = TR.NetworkNo AND
                            TR.TVEPartnerTypeNo = @PartnerTypeNo
WHERE ISNULL(StatusRule, 'Y') <> 'N'
ORDER BY StartDate, DayOfWeekNo, StartTime

UPDATE t1
SET t1.ScheduleNo=t2.OLayScheduleNo FROM #FinalScheduleItemResult t1
                                 INNER JOIN #AllSchedules t2
ON t1.ScheduleNo = t2.ScheduleNo
SELECT SIR.*, '' as StatusRule, '' as ExceptionMessage
FROM #ScheduleItemResult SIR
         INNER JOIN #OriginalSchedules OS ON SIR.ScheduleNo = OS.ScheduleNo
UNION
SELECT *
FROM #FinalScheduleItemResult
DROP TABLE #FinalScheduleItemResult


END
ELSE
BEGIN

SELECT @ScheduleRightTypeNo = TVERightTypeNo
FROM TVERightTypeFeed TRT
WHERE FeedNo = @TVEFeedNo

SELECT SIR.*, ISNULL(TTR.TitleTVERightStatus, 'Y') as StatusRule, '' as ExceptionMessage
into #FinalScheduleItemResult1
FROM #ScheduleItemResult SIR
         INNER JOIN #TVESchedules TS ON SIR.ScheduleNo = TS.ScheduleNo
         LEFT OUTER JOIN vw_TitleTVERight TTR
                         ON SIR.TitleNo = TTR.TitleNo AND SIR.NetworkNo = TTR.NetworkNo AND
                            TTR.TVERightTypeNo = @ScheduleRightTypeNo AND TTR.DelFlag = 'N'
WHERE ISNULL(TTR.TitleTVERightStatus, 'Y') = 'Y'
ORDER BY StartDate, DayOfWeekNo, StartTime
UPDATE t1
SET t1.ScheduleNo=t2.OLayScheduleNo FROM #FinalScheduleItemResult1 t1
                                 INNER JOIN #AllSchedules t2
ON t1.ScheduleNo = t2.ScheduleNo
SELECT SIR.*, 'Y' as StatusRule, '' as ExceptionMessage
FROM #ScheduleItemResult SIR
         INNER JOIN #OriginalSchedules OS ON SIR.ScheduleNo = OS.ScheduleNo
UNION
SELECT *
FROM #FinalScheduleItemResult1
DROP TABLE #FinalScheduleItemResult1


END

END
ELSE
BEGIN
SELECT *
FROM #ScheduleItemResult
ORDER BY StartDate1, DayOfWeekNo, StartTime1
END

DROP TABLE #AllSchedules
DROP TABLE #Schedule
DROP TABLE #ScheduleItem
DROP TABLE #DOW
DROP TABLE #OriginalSchedules
DROP TABLE #TVESchedules
DROP TABLE #ScheduleItemResult

END TRY
BEGIN CATCH
        DECLARE
@ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @vDatabase_ID INT
SELECT @ErrorMessage = ERROR_MESSAGE(),
       @ErrorSeverity = ERROR_SEVERITY(),
       @vDatabase_ID = DB_ID(),
       @ErrorState = ERROR_STATE(); -- Incase the application IS able to raise errors, use both Begin Try..End Try and Raise Error
RAISERROR
( @ErrorMessage, @ErrorSeverity, @ErrorState); -- Message text, Severity, State
        EXECUTE
[dba_admin].[dbo].[s_LogSQLError] @DATABASE_ID = @vDatabase_ID; -- Execute error retrieval routine.
END CATCH;
END
  