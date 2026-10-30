using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DAL.PoliMusicV3
{
    public class Song
    {
        private readonly string strConnectionString;

        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        public DataTable Read()
        {
            DataTable dtSongs = new DataTable();

            using (SqlConnection con =
                new SqlConnection(strConnectionString))
            {
                string sql = @"
                    SELECT
                        ID_SONG,
                        SONG_NAME,
                        SONG_PATH,
                        PLAYS
                    FROM TBL_SONG
                    ORDER BY ID_SONG";

                using (SqlCommand cmd =
                    new SqlCommand(sql, con))
                {
                    using (SqlDataAdapter adapter =
                        new SqlDataAdapter(cmd))
                    {
                        adapter.Fill(dtSongs);
                    }
                }
            }

            return dtSongs;
        }
    }
}
