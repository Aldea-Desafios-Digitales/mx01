IF OBJECT_ID ('dbo.SplitStrings') IS NOT NULL
   DROP FUNCTION dbo.SplitStrings
GO

create FUNCTION dbo.SplitStrings (
    @List NVARCHAR(MAX),
    @Delimiter NVARCHAR(255)
) RETURNS TABLE AS RETURN (
    SELECT
        Number = ROW_NUMBER() OVER (
            ORDER BY
                Number
        ),
        Item
    FROM
        (
            SELECT
                Number,
                Item = LTRIM(
                    RTRIM(
                        SUBSTRING(
                            @List,
                            Number,
                            CHARINDEX(@Delimiter, @List + @Delimiter, Number) - Number
                        )
                    )
                )
            FROM
                (
                    SELECT top 1000
                        ROW_NUMBER() OVER (
                            ORDER BY
                                s1.[object_id]
                        )
                    FROM
                        sys.all_objects AS s1
                        CROSS APPLY sys.all_objects
                ) AS n(Number)
            WHERE
                Number <= CONVERT(INT, LEN(@List))
                AND SUBSTRING(@Delimiter + @List, Number, 1) = @Delimiter
        ) AS y
);

GO

IF (@@Error = 0) PRINT 'Creación exitosa de la función: SplitStrings ()'
ELSE PRINT 'Error en la creación de la función: SplitStrings ()'
GO

----------------------------------------------------------------------------------------------------------------------
-- select *
-- from dbo.SplitStrings ('  abc;hij;  dkdl;LPLJ;'+char(10)+char(13)+'hola', ';')

