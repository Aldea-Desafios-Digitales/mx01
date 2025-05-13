-----------------------------------------------------------------------------------------------------------------------------
IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'dbo.nfMCP20000') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
    CREATE TABLE [dbo].[nfMCP20000](
        [MCPTYPID] [char](21) NOT NULL,
        [NUMBERIE] [char](21) NOT NULL,
        [ENTITY] [smallint] NOT NULL,
        [NFENTID] [char](15) NOT NULL,
        [VOIDSTTS] [smallint] NOT NULL,
        [VOIDDATE] [datetime] NOT NULL,
        [CURNCYID] [char](15) NOT NULL,
        [BACHNUMB] [char](15) NOT NULL,
        [BCHSOURC] [char](15) NOT NULL,
        [TOTAMNT] [numeric](19, 5) NOT NULL,
        [CURTRXAM] [numeric](19, 5) NOT NULL,
        [DOCDATE] [datetime] NOT NULL,
        [REFRENCE] [char](31) NOT NULL,
        [STSDESCR] [char](31) NOT NULL,
        [CSHAPPLY] [tinyint] NOT NULL,
        [MEDAPPLY] [tinyint] NOT NULL,
        [RMTREMSG] [binary](4) NOT NULL,
        [RMDPEMSG] [binary](4) NOT NULL,
        [POSTED] [tinyint] NOT NULL,
        [RMDTYPAL] [smallint] NOT NULL,
        [GLPOSTDT] [datetime] NOT NULL,
        [LSTEDTDT] [datetime] NOT NULL,
        [LSTUSRED] [char](15) NOT NULL,
        [nfMCP_Printing_Number] [char](15) NOT NULL,
        [WROFAMNT] [numeric](19, 5) NOT NULL,
        [DISTKNAM] [numeric](19, 5) NOT NULL,
        [DISAVTKN] [numeric](19, 5) NOT NULL,
        [PRINTED] [tinyint] NOT NULL,
        [NOTEINDX] [numeric](19, 5) NOT NULL,
        [DEX_ROW_ID] [int] IDENTITY(1,1) NOT NULL,
    CONSTRAINT [PKnfMCP20000] PRIMARY KEY NONCLUSTERED 
    (
        [MCPTYPID] ASC,
        [NUMBERIE] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    ) ON [PRIMARY]
end
------------------------------------------------------------------------------------------------------------------------------
IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'dbo.nfmcp20100') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	create table dbo.nfmcp20100
	(
	[MCPTYPID] [char](21) NOT NULL,
	[NUMBERIE] [char](21) NOT NULL,
	[LNSEQNBR] [numeric](19, 5) NOT NULL,
	[MEDIOID] [char](21) NOT NULL,
	[BANKID] [char](15) NOT NULL,
	[DOCNUMBR] [char](21) NOT NULL,
	[LOCATNNM] [char](31) NOT NULL,
	[TITACCT] [char](65) NOT NULL,
	[EMIDATE] [datetime] NOT NULL,
	[DUEDATE] [datetime] NOT NULL,
	[LINEAMNT] [numeric](19, 5) NOT NULL,
	[AMOUNTO] [numeric](19, 5) NOT NULL,
	[CURNCYID] [char](15) NOT NULL,
	[STSDESCR] [char](31) NOT NULL,
	[CURRNIDX] [smallint] NOT NULL,
	[BANACTID] [char](21) NOT NULL,
	[TII_MCP_Clearing] [smallint] NOT NULL,
	[TII_MCP_Checkbook_Integ] [tinyint] NOT NULL,
	[TII_MCP_Integrated_Date] [datetime] NOT NULL,
	[TII_CHEKBKID] [char](15) NOT NULL,
	[TXRGNNUM] [char](25) NOT NULL,
	[DEX_ROW_ID] [int] IDENTITY(1,1) NOT NULL
	) on [PRIMARY];
end

IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'dbo.nfMCP_PM20100') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	CREATE TABLE [dbo].[nfMCP_PM20100](
		[MCPTYPID] [char](21) NOT NULL,
		[NUMBERIE] [char](21) NOT NULL,
		[MEDIOID] [char](21) NOT NULL,
		[BANKID] [char](15) NOT NULL,
		[DOCNUMBR] [char](21) NOT NULL,
		[TITACCT] [char](65) NOT NULL,
		[EMIDATE] [datetime] NOT NULL,
		[DUEDATE] [datetime] NOT NULL,
		[LINEAMNT] [numeric](19, 5) NOT NULL,
		[AMOUNTO] [numeric](19, 5) NOT NULL,
		[CURNCYID] [char](15) NOT NULL,
		[STSDESCR] [char](31) NOT NULL,
		[LNSEQNBR] [numeric](19, 5) NOT NULL,
		[CHEKBKID] [char](15) NOT NULL,
		[BANACTID] [char](21) NOT NULL,
		[CURRNIDX] [smallint] NOT NULL,
		[TII_MCP_Realized_Gain_Lo] [numeric](19, 5) NOT NULL,
		[TII_MCP_Clearing] [smallint] NOT NULL,
		[TII_MCP_Checkbook_Integ] [tinyint] NOT NULL,
		[TII_MCP_Integrated_Date] [datetime] NOT NULL,
		[TII_CHEKBKID] [char](15) NOT NULL,
		[VOIDED] [tinyint] NOT NULL,
		[VOIDDATE] [datetime] NOT NULL,
		[TXRGNNUM] [char](25) NOT NULL,
		[DEX_ROW_ID] [int] IDENTITY(1,1) NOT NULL,
	 CONSTRAINT [PKnfMCP_PM20100] PRIMARY KEY NONCLUSTERED 
	(
		[MCPTYPID] ASC,
		[NUMBERIE] ASC,
		[MEDIOID] ASC,
		[LNSEQNBR] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
end

-----------------------------------------------------------------------------------------------------------------------------
IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'dbo.nfmcp30100') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	create table dbo.nfmcp30100
	(
	[NUMBERIE] [char](21) NOT NULL,
	[MEDIOID] [char](21) NOT NULL,
	[LINEAMNT] [numeric](19, 5) NOT NULL,
	[TII_CHEKBKID] [char](15) NOT NULL,
	[DEX_ROW_ID] [int] IDENTITY(1,1) NOT NULL
	) on [PRIMARY];
end

-----------------------------------------------------------------------------------------------------------------------------
IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'dbo.nfmcp00700') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	create table dbo.nfmcp00700
	(
	[GRUPID] [char](21) NOT NULL,
	[MEDIOID] [char](21) NOT NULL,
	[CHEKBKID] [char](15) NOT NULL
	) on [PRIMARY];
end

GO
