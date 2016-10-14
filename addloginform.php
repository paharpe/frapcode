<?php function display_login_form() { ?>

<html lang = "en">
 <link href = "css/bootstrap.min.css" rel = "stylesheet">

      <style>
         body {
            padding-top: 40px;
            padding-bottom: 40px;
            background-color: #ADABAB;
         }

         .form-signin {
            max-width: 330px;
            padding: 15px;
            margin: 0 auto;
            color: #017572;
         }

         .form-signin .form-signin-heading,
         .form-signin .checkbox {
            margin-bottom: 10px;
         }

         .form-signin .checkbox {
            font-weight: normal;
         }

         .form-signin .form-control {
            position: relative;
            height: auto;
            -webkit-box-sizing: border-box;
            -moz-box-sizing: border-box;
            box-sizing: border-box;
            padding: 10px;
            font-size: 16px;
         }

         .form-signin .form-control:focus {
            z-index: 2;
         }

         h1{
            text-align: center;
            color: #017572;
         }
         p{
            text-align: center;
            color: #017572;
         }

      </style>




   <head>
      <title>AMIS Job Page</title>
      <link href = "css/bootstrap.min.css" rel = "stylesheet">
   </head>
   <body>
      <h1>AMIS Job Page</h2>
      <div class = "container form-signin">
      </div>

      <div class = "container">
         <form class = "form-signin" role = "form" action = "<?php echo $self; ?>" method = "post">
            <input type="text" class="form-control" name="username" required autofocus></br>
            <input type="password" class="form-control" name="password" required>
            <br> <br/>
            <button class="btn btn-lg btn-primary btn-block" type="submit" name="submit" value="submit">Login</button>
         </form>

      </div>

   </body>
</html>
<?php }

function  addhtml(){?>
<html lang = "en">
 <link href = "css/bootstrap.min.css" rel = "stylesheet">
      <style>
         body {
            padding-top: 40px;
            padding-bottom: 40px;
            background-color: #ADABAB;
         }

         .form-signin {
            max-width: 330px;
            padding: 15px;
            margin: 0 auto;
            color: #017572;
         }

         .form-signin .form-signin-heading,
         .form-signin .checkbox {
            margin-bottom: 10px;
         }

         .form-signin .checkbox {
            font-weight: normal;
         }

         .form-signin .form-control {
            position: relative;
            height: auto;
            -webkit-box-sizing: border-box;
            -moz-box-sizing: border-box;
            box-sizing: border-box;
            padding: 10px;
            font-size: 16px;
         }

         .form-signin .form-control:focus {
            z-index: 2;
         }

         h1{
            text-align: center;
            color: #017572;
         }
         p{
            text-align: center;
            color: #017572;
         }

      </style>
   <head>
      <title>AMIS Job Page</title>
      <link href = "css/bootstrap.min.css" rel = "stylesheet">
   </head>
   <body>
<?php } ?>



