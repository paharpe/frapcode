<?php
require('addloginform.php');
session_start();
  $username = 'admin';
  $password = 'test123';
  $info = array(
        'jobname_acc' => 'run command 1',
        'jobname_prod' => 'run command 2',
         'host_acc'             => 'su444v1028',
         'host_prod'            => 'su444v1031',
         'job_desc'                     => 'asp-replicate-yaml',);
  $random1 = 'secret_key1';
  $random2 = 'secret_key2';
  $inhoud = 'clicked command run';
  $hash = md5($random1.$pass.$random2);

  $self = $_SERVER['REQUEST_URI'];

  $command = $info['host_acc'];
  #$command2 = shell_exec('pwd');
  $command2 = $info['host_prod'];
//misschien wel -- of niet jonge?
// **********   USER LOGOUT  ********** //
  if(isset($_GET['logout'])) {
    unset($_SESSION['login']);
  }

  // **********   USER IS LOGGED IN       ********** //
  if (isset($_SESSION['login']) && $_SESSION['login'] == $hash) {
addhtml();
?>

<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="get">

<img src="logo-kpn-groot.png"/> <font color="gray" fontsize="7" face="verdana"> Jobspage </font>

<h2 class="green"><font color="green">Maak een keuze uit onderstaande acties</font></h2>
    <?php
    ?>

    <table style="margin-top:10px; margin-left:10px;">
        <tr>
            <td><b><u><label for="jobname">Jobname:</label></b></u></td>
            <td><b><u><label for="host">Host:</label></b></u></td>
            <td><b><u><label for="description">Description</label</b></u></td>
            <td><b><u><label for="run">Run this job</label></b></u></td>
        </tr>
        <tr>
            <td><span class="form-control input-sm" name="description"><?php echo $info['jobname_acc'] ?></span></td>
            <td><span class="form-control input-sm" name="description"><?php echo $info['host_acc'] ?></span></td>
            <td><span class="form-control input-sm" name="description"><?php echo $info['job_desc'] ?></span></td>
            <td>
            <input Type="submit" class="btn btn-primary btn-sm" Value="Run" name="Command1">


            </td>
        </tr>
        <tr>

            <td><span class="form-control input-sm" name="description"><?php echo $info['jobname_prod'] ?></span></td>
            <td><span class="form-control input-sm" name="description"><?php echo $info['host_prod'] ?></span></td>
            <td><span class="form-control input-sm" name="description"><?php echo $info['job_desc'] ?></span></td>
            <td>
            <input Type="submit" class="btn btn-primary btn-sm" Value="Run" name="Command2">


            </td>
        </tr>

    </table>
    <br />

    <?php if (isset($_GET['Command1'])){ ?>
                 <textarea name="textarea" id="textarea" cols="45" rows="5"><?php echo $command; ?></textarea>
    <?php }
                 elseif (isset($_GET['Command2'])){ ?>
                 <textarea name="textarea" id="textarea" cols="45" rows="5"><?php echo $command2; ?></textarea>
   <?php } else{ ?>
      <textarea name="textarea" id="textarea" cols="45" rows="5">Run command!</textarea>
    <?php } ?>
  </br>
    <input type="submit" class="btn btn-primary" name="logout" value="Logout"/>
  </form>
  </body>
  </html>

<?php

}

// **********   FORM HAS BEEN SUBMITTED ********** //
else if (isset($_POST['submit'])) {
  if ($_POST['username'] == $username && $_POST['password'] == $password){
    //IF USERNAME AND PASSWORD ARE CORRECT SET THE LOG-IN SESSION
    $_SESSION["login"] = $hash;
    header("Location: $_SERVER[PHP_SELF]");
  }
  else {
    // DISPLAY FORM WITH ERROR
    display_login_form();
    echo '<p>Username or password is invalid</p>';
  }
}


// **********   SHOW THE LOG-IN FORM    ********** //
else {
  display_login_form();
}



