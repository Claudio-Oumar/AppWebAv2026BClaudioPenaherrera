
<%@ Page Title="Canciones"
    Language="C#"
    MasterPageFile="~/Site.Master"
    AutoEventWireup="true"
    CodeBehind="Song.aspx.cs"
    Inherits="WebAppPoliMusicV3.Song" %>

<asp:Content ID="Content1"
    ContentPlaceHolderID="MainContent"
    runat="server">

    <style>
        .songs-container {
            padding: 30px 0;
        }

        .songs-title {
            font-size: 30px;
            font-weight: 700;
            margin-bottom: 10px;
        }

        .songs-subtitle {
            color: #64748b;
            margin-bottom: 25px;
        }

        .songs-table {
            width: 100%;
            background: white;
        }

        .songs-table th {
            background: #f1f5f9;
            font-weight: 600;
        }

        .songs-table td {
            vertical-align: middle;
        }

        .song-player {
            width: 240px;
            max-width: 100%;
            height: 40px;
        }
    </style>

    <div class="container songs-container">

        <asp:Label
            ID="lblUsuario"
            runat="server"
            Font-Bold="true">
        </asp:Label>

        <h2 class="songs-title">
            Biblioteca de canciones
        </h2>

        <p class="songs-subtitle">
            Consulta y reproduce las canciones
            disponibles en PoliMusic.
        </p>

        <asp:Label
            ID="lblMessage"
            runat="server"
            ForeColor="Red">
        </asp:Label>

        <div class="table-responsive">

            <asp:GridView
                ID="GridViewSongs"
                runat="server"
                AutoGenerateColumns="False"
                CssClass="table table-bordered table-hover songs-table"
                GridLines="None"
                EmptyDataText="No hay canciones registradas.">

                <Columns>

                    <asp:BoundField
                        DataField="ID_SONG"
                        HeaderText="ID Canción" />

                    <asp:BoundField
                        DataField="SONG_NAME"
                        HeaderText="Nombre" />

                    <asp:BoundField
                        DataField="SONG_PATH"
                        HeaderText="Ruta" />

                    <asp:BoundField
                        DataField="PLAYS"
                        HeaderText="Reproducciones" />

                    <asp:TemplateField
                        HeaderText="Reproducir">

                        <ItemTemplate>

                            <audio
                                class="song-player"
                                controls="controls"
                                preload="none">

                                <source
                                    src='<%# GetAudioUrl(Eval("SONG_PATH")) %>'
                                    type="audio/mpeg" />

                                Tu navegador no soporta audio.

                            </audio>

                        </ItemTemplate>

                    </asp:TemplateField>

                </Columns>

            </asp:GridView>

        </div>

    </div>

    <script>
        document.addEventListener("play", function (event) {
            if (event.target.tagName === "AUDIO") {
                document.querySelectorAll("audio")
                    .forEach(function (player) {
                        if (player !== event.target) {
                            player.pause();
                        }
                    });
            }
        }, true);
    </script>

</asp:Content>
