using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV3
{
    public partial class Song : System.Web.UI.Page
    {
        private readonly string strConnString =
            ConfigurationManager.ConnectionStrings[
                "BDD_PoliMusicConnectionString"
            ].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                var usuario = Session[
                    EntityLayer.PoliMusicV3.Util.Constants.USER
                ] as EntityLayer.PoliMusicV3.User;

                if (usuario == null)
                {
                    Response.Redirect("~/Login.aspx");
                    return;
                }

                lblUsuario.Text =
                    "Bienvenido, " +
                    Server.HtmlEncode(usuario.UserName);

                LoadSongs();
            }
        }

        private void LoadSongs()
        {
            try
            {
                BLL.PoliMusicV3.Song songBLL =
                    new BLL.PoliMusicV3.Song(strConnString);

                DataTable dtSongs = songBLL.Read();

                GridViewSongs.DataSource = dtSongs;
                GridViewSongs.DataBind();

                if (dtSongs.Rows.Count == 0)
                {
                    lblMessage.Text =
                        "No existen canciones registradas.";
                }
                else
                {
                    lblMessage.Text = string.Empty;
                }
            }
            catch (Exception)
            {
                lblMessage.Text =
                    "No se pudo cargar la lista de canciones.";
            }
        }

        protected string GetAudioUrl(object songPath)
        {
            if (songPath == null ||
                songPath == DBNull.Value)
            {
                return string.Empty;
            }

            string ruta = songPath.ToString().Trim();

            // Obtener solamente el nombre del archivo.
            string fileName = Path.GetFileName(
                ruta.Replace('/', '\\')
            );

            if (string.IsNullOrEmpty(fileName) ||
                !fileName.EndsWith(
                    ".mp3",
                    StringComparison.OrdinalIgnoreCase))
            {
                return string.Empty;
            }

            // Resolver desde la carpeta web SongFiles.
            return ResolveUrl(
                "~/SongFiles/" +
                Uri.EscapeDataString(fileName)
            );
        }
    }
}