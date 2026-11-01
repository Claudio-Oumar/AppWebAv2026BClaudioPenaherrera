using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Web;

namespace WebAppPoliMusicV2.DAL
{
    public class Song
    {
        private string strConnectionString;

        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        public DataTable Read()
        {
            DataTable dtSongs = new DataTable();

            using (SqlConnection con = new SqlConnection(strConnectionString))
            {
                string sentence = "SELECT [ID_SONG], [SONG_NAME], [SONG_PATH], [PLAYS] " +
                    "FROM [TBL_SONG] ORDER BY [ID_SONG]";

                using (SqlCommand cmd = new SqlCommand(sentence, con))
                {
                    using (SqlDataAdapter sda = new SqlDataAdapter(cmd))
                    {
                        sda.Fill(dtSongs);
                    }
                }
            }

            return dtSongs;
        }
    }
}
